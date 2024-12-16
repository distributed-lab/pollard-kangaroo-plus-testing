import { ExtPointType } from '@noble/curves/abstract/edwards';
import { ed25519, RistrettoPoint } from '@noble/curves/ed25519';

import { log } from 'console';
import * as fs from 'fs';

type RistPoint = InstanceType<typeof RistrettoPoint>;

export class TableMap{
    s: RistPoint[];
    slog: bigint[];
    table: Map<bigint, bigint>

    constructor() {
        this.s = new Array<RistPoint>
        this.slog = new Array<bigint>
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

    // Method to serialize the TableMap to JSON format

    // Static method to create a TableMap from JSON data
    readJson(jsonString: string) {
        const parsedData = JSON.parse(jsonString);

        const s = parsedData.s.map((value: string) => RistrettoPoint.fromHex(value));
        const slog = parsedData.slog.map((value: string) => BigInt('0x' + value));
        const table = new Map<bigint, bigint>(
            parsedData.table.map((entry: { point: string; value: string }) => [
                BigInt('0x' + entry.point),
                BigInt('0x' + entry.value)
            ])
        );

        this.s = s
        this.slog = slog
        this.table = table
    }
}