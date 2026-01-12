export const propertyMap: Map<string, number> = new Map();
export const globalCallSites: string[] = [];
export const binaryOpCallSites: string[] = [];
export const generatedFunctions: string[] = [];

// New string pooling maps
export const stringMap: Map<string, string> = new Map();
export const stringDataSegments: string[] = [];

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
    // We can use JSON.stringify to handle escapes, but we need to strip quotes
    // and make sure it's WAT compatible.
    // Actually, binaryen parseText supports "..."
    // But we need to be careful about non-printable chars.
    // Let's use hex escapes for safety if needed, or just standard JSON escaping.
    // For now, let's trust JSON.stringify but remove surrounding quotes.
    const escaped = JSON.stringify(text).slice(1, -1);
    stringDataSegments.push(`(data ${name} "${escaped}")`);
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

    lookup(name: string): { type: 'local' | 'captured' | 'global', typeName?: string } {
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
