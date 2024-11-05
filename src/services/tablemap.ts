import * as fs from 'fs';

export class TableMap{
    table: Map<bigint, bigint>

    constructor() {
        this.table = new Map<bigint, bigint>
    }

    get(key: bigint): bigint | undefined {
        return this.table.get(key)
    }

    set(key: bigint, value: bigint) {
        this.table.set(key, value)
    }

    // Helper function to convert a hex string to a Uint8Array
    private hexStringToBytes(hex: string): Uint8Array {
        let bytes = new Uint8Array(hex.length / 2);
        for (let i = 0; i < hex.length; i += 2) {
            bytes[i / 2] = parseInt(hex.slice(i, i + 2), 16);
        }
        return bytes;
    }

    // Helper function to convert a Uint8Array to a hex string
    private bytesToHexString(bytes: Uint8Array): string {
        return Array.from(bytes)
            .map(byte => byte.toString(16).padStart(2, '0'))
            .join('');
    }

    // Function to write data to a file
    writeToFile(path: string): boolean {
        try {
            console.log(new URL(path, import.meta.url))
            const outFile = fs.openSync(new URL(path, import.meta.url), 'w');

            // Write the size of the map
            const mapSize = this.table.size;
            const sizeBuffer = Buffer.alloc(8); // Assuming 64-bit size
            sizeBuffer.writeBigUInt64LE(BigInt(mapSize));
            fs.writeSync(outFile, sizeBuffer);

            // Write each entry in the map
            for (const [key, value] of this.table.entries()) {
                // Convert the hex string key to bytes
                const keyBytes = key.toString(16);
                const keySizeBuffer = Buffer.alloc(8);
                keySizeBuffer.writeBigUInt64LE(BigInt(keyBytes.length/2));
                fs.writeSync(outFile, keySizeBuffer);
                fs.writeSync(outFile, Buffer.from(keyBytes));

                // Serialize the log as a string
                const logBuffer = value.toString(16);
                const logSizeBuffer = Buffer.alloc(8);
                logSizeBuffer.writeBigUInt64LE(BigInt(logBuffer.length/2));
                fs.writeSync(outFile, logSizeBuffer);
                fs.writeSync(outFile, logBuffer);
            }

            fs.closeSync(outFile);
            return true;
        } catch (error) {
            console.error(`Error: Unable to open file for writing: ${path}`);
            return false;
        }
    }

    readFromBuffer(buffer: Buffer): boolean {
        try {
            // Clear the current map
            this.table.clear();
    
            let offset = 0;
    
            // Read the size of the map
            const mapSize = Number(buffer.readBigUInt64LE(offset));
            offset += 8;
    
            // Read each entry in the map
            for (let i = 0; i < mapSize; i++) {
                const keySize = Number(buffer.readBigUInt64LE(offset));
                offset += 8;
    
                const keyBytes = buffer.slice(offset, offset + keySize);
                const key = this.bytesToHexString(new Uint8Array(keyBytes));
                offset += keySize;
    
                const logSize = Number(buffer.readBigUInt64LE(offset));
                offset += 8;
    
                const logBuffer = buffer.slice(offset, offset + logSize);
                const logStr = logBuffer.toString();
                offset += logSize;
    
                // Insert the read values into the map
                this.table.set(BigInt('0x' + key), BigInt('0x' + logStr));
            }
    
            return true;
        } catch (error) {
            console.error(`Error: Unable to read data from buffer`);
            return false;
        }
    }    
}