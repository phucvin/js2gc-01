import * as fs from 'fs';
import * as path from 'path';

const testdataDir = 'testdata';
const files = fs.readdirSync(testdataDir).filter(f => f.endsWith('.wat') && !f.endsWith('.optimized.wat'));

const optimizationStats: Record<string, string[]> = {};

files.forEach(file => {
  const filepath = path.join(testdataDir, file);
  let content = fs.readFileSync(filepath, 'utf8');
  const optimizationsApplied: string[] = [];

  // Optimization 1: Remove redundant drop of ref.null none
  // Pattern: (drop (ref.null none)) with flexible whitespace
  const dropRegex = /\s*\(drop\s+\(ref\.null\s+none\s*\)\s*\)/g;
  if (dropRegex.test(content)) {
    content = content.replace(dropRegex, '');
    optimizationsApplied.push('Removed redundant (drop (ref.null none))');
  }

  // Optimization 2: Optimize add_cached
  // We look for the specific structure of add_cached
  const addCachedRegex = /(\(func \$add_cached \(type \$\d+\) \(param \$lhs anyref\) \(param \$rhs anyref\) \(param \$cache \(ref \$BinaryOpCallSite\)\) \(result anyref\)\n)\s+\(if \(result anyref\)\n\s+\(i32\.and\n\s+\(i32\.eq\n\s+\(call \$get_type_id\n\s+\(local\.get \$lhs\)\n\s+\)\n\s+\(struct\.get \$BinaryOpCallSite \$type_lhs\n\s+\(local\.get \$cache\)\n\s+\)\n\s+\)\n\s+\(i32\.eq\n\s+\(call \$get_type_id\n\s+\(local\.get \$rhs\)\n\s+\)\n\s+\(struct\.get \$BinaryOpCallSite \$type_rhs\n\s+\(local\.get \$cache\)\n\s+\)\n\s+\)\n\s+\)\n\s+\(then\n\s+\(call_ref \$BinaryOpFunc\n\s+\(local\.get \$lhs\)\n\s+\(local\.get \$rhs\)\n\s+\(ref\.as_non_null\n\s+\(struct\.get \$BinaryOpCallSite \$target\n\s+\(local\.get \$cache\)\n\s+\)\n\s+\)\n\s+\)\n\s+\)\n\s+\(else\n\s+\(call \$add_slow\n\s+\(local\.get \$lhs\)\n\s+\(local\.get \$rhs\)\n\s+\(local\.get \$cache\)\n\s+\)\n\s+\)\n\s+\)/;

  if (addCachedRegex.test(content)) {
    content = content.replace(addCachedRegex, (match, funcHeader) => {
      return `${funcHeader}
  (block $slow
   (br_if $slow
    (i32.ne
     (call $get_type_id
      (local.get $lhs)
     )
     (struct.get $BinaryOpCallSite $type_lhs
      (local.get $cache)
     )
    )
   )
   (br_if $slow
    (i32.ne
     (call $get_type_id
      (local.get $rhs)
     )
     (struct.get $BinaryOpCallSite $type_rhs
      (local.get $cache)
     )
    )
   )
   (return
    (call_ref $BinaryOpFunc
     (local.get $lhs)
     (local.get $rhs)
     (ref.as_non_null
      (struct.get $BinaryOpCallSite $target
       (local.get $cache)
      )
     )
    )
   )
  )
  (call $add_slow
   (local.get $lhs)
   (local.get $rhs)
   (local.get $cache)
  )`;
    });
    optimizationsApplied.push('Optimized add_cached with short-circuiting');
  }

  // Optimization 3: local.tee for new object creation pattern
  // Pattern: (local.set $var (call ...)) followed by (ref.as_non_null (local.get $var))
  // This is hard to do with regex safely across all files without parsing.
  // Skipping for now to avoid breaking code.

  if (optimizationsApplied.length > 0) {
    const optimizedFilepath = filepath.replace('.wat', '.optimized.wat');
    fs.writeFileSync(optimizedFilepath, content);
    optimizationStats[file] = optimizationsApplied;
  } else {
    // Write even if no optimization found (as a copy) or skip?
    // User asked to "write the expected optimized wat files". If no optimization, it's same as original.
    const optimizedFilepath = filepath.replace('.wat', '.optimized.wat');
    fs.writeFileSync(optimizedFilepath, content);
    optimizationStats[file] = ['No specific optimization applied (just copy)'];
  }
});

console.log('Optimizations applied:');
console.log(JSON.stringify(optimizationStats, null, 2));
