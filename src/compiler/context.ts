export const propertyMap: Map<string, number> = new Map();
export const globalCallSites: string[] = [];
export const binaryOpCallSites: string[] = [];
export const generatedFunctions: string[] = [];

// New string pooling maps
export const stringMap: Map<string, string> = new Map();
export const stringDataSegments: string[] = [];

// Shape caching
export const shapeCache: Map<string, string> = new Map();
export const shapeGlobals: string[] = [];

export function getPropertyId(name: string): number {
  if (!propertyMap.has(name)) {
    propertyMap.set(name, propertyMap.size);
  }
  return propertyMap.get(name)!;
}

export function resetPropertyMap() {
  propertyMap.clear();
}

export function resetGlobalCallSites() {
  globalCallSites.length = 0;
  binaryOpCallSites.length = 0;
}

// Reset strings
export function resetStringMap() {
  stringMap.clear();
  stringDataSegments.length = 0;
}

export function resetShapeCache() {
  shapeCache.clear();
  shapeGlobals.length = 0;
}

export function registerGlobalCallSite(): string {
  const name = `$site_${globalCallSites.length}`;
  globalCallSites.push(name);
  return name;
}

export function registerBinaryOpCallSite(): string {
  const name = `$site_bin_${binaryOpCallSites.length}`;
  binaryOpCallSites.push(name);
  return name;
}

export function registerGeneratedFunction(code: string) {
  generatedFunctions.push(code);
}

export function resetGeneratedFunctions() {
  generatedFunctions.length = 0;
}

// Register string literal
export function registerStringLiteral(text: string): string {
  if (stringMap.has(text)) {
    return stringMap.get(text)!;
  }
  const name = `$str_data_${stringMap.size}`;
  stringMap.set(text, name);
  // Escape string for WAT
  const escaped = JSON.stringify(text).slice(1, -1);
  stringDataSegments.push(`(data ${name} "${escaped}")`);
  return name;
}

// Register Object Literal Shape
export function registerShape(keys: string[]): string {
  const keyStr = keys.join(',');
  if (shapeCache.has(keyStr)) {
    return shapeCache.get(keyStr)!;
  }

  const name = `$shape_literal_${shapeCache.size}`;
  shapeCache.set(keyStr, name);

  // Build the nested struct.new chain
  // Root: (struct.new $Shape (ref.null $Shape) (i32.const -1) (i32.const -1) (ref.null any))
  let shapeCode = `(struct.new $Shape (ref.null $Shape) (i32.const -1) (i32.const -1) (ref.null any))`;

  // Extend for each key
  keys.forEach((key, index) => {
    const id = getPropertyId(key);
    // $extend_shape logic: (struct.new $Shape parent key offset proto)
    // For object literals, proto is null (or rather, the root shape has null proto, and extensions inherit it)
    // Wait, $extend_shape implementation in index.ts copies proto from parent.
    // Here we are statically constructing it.
    // The root shape has null proto.
    // The extensions should effectively also have null proto (inherited from root).
    shapeCode = `(struct.new $Shape ${shapeCode} (i32.const ${id}) (i32.const ${index}) (ref.null any))`;
  });

  // Define the global
  // It's an immutable global initialized with a constant expression
  shapeGlobals.push(`(global ${name} (ref $Shape) ${shapeCode})`);

  return name;
}

export interface CompilerOptions {
  enableInlineCache?: boolean;
}

export class CompilationContext {
  private locals: Map<string, string> = new Map();
  private tempCounter: number = 0;
  private parent?: CompilationContext;
  private captured: Set<string> = new Set();
  private options: CompilerOptions;

  constructor(parentOrOptions?: CompilationContext | CompilerOptions) {
    if (parentOrOptions instanceof CompilationContext) {
      this.parent = parentOrOptions;
      this.options = this.parent.options;
    } else {
      this.options = (parentOrOptions as CompilerOptions) || {};
    }
  }

  addLocal(name: string, type: string) {
    this.locals.set(name, type);
  }

  hasLocal(name: string): boolean {
    return this.locals.has(name);
  }

  getLocals(): Map<string, string> {
    return this.locals;
  }

  getTempLocal(type: string): string {
    const name = `$temp_${this.tempCounter++}`;
    this.addLocal(name, type);
    return name;
  }

  getUniqueLocalName(prefix: string): string {
    return `${prefix}${this.tempCounter++}`;
  }

  updateLocalType(name: string, type: string) {
    this.locals.set(name, type);
  }

  lookup(name: string): { type: 'local' | 'captured' | 'global'; typeName?: string } {
    if (this.locals.has(name)) {
      return { type: 'local', typeName: this.locals.get(name) };
    }
    if (this.parent) {
      const res = this.parent.lookup(name);
      if (res.type === 'local' || res.type === 'captured') {
        this.captured.add(name);
        return { type: 'captured', typeName: 'anyref' };
      }
    }
    return { type: 'global' };
  }

  getCapturedVars(): string[] {
    return Array.from(this.captured);
  }

  getOptions(): CompilerOptions {
    return this.options;
  }
}
