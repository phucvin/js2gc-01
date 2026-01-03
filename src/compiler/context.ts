export const propertyMap: Map<string, number> = new Map();
export const globalCallSites: string[] = [];
export const binaryOpCallSites: string[] = [];
export const generatedFunctions: string[] = [];

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

export interface CompilerOptions {
    enableInlineCache?: boolean;
    enableStringRef?: boolean;
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
