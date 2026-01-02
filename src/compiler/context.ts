export const propertyMap: Map<string, number> = new Map();
export const globalCallSites: string[] = [];

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
}

export function registerGlobalCallSite(): string {
    const name = `$site_${globalCallSites.length}`;
    globalCallSites.push(name);
    return name;
}

export class CompilationContext {
    private locals: Map<string, string> = new Map();
    private tempCounter: number = 0;

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
}
