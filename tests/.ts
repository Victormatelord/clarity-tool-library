import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can add new tool as contract owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        let block = chain.mineBlock([
            Tx.contractCall('tool-rental', 'add-tool', [
                types.uint(1),
                types.ascii("Power Drill"),
                types.uint(100)
            ], deployer.address)
        ]);
        assertEquals(block.receipts[0].result.expectOk(), true);
    }
});

Clarinet.test({
    name: "Can rent an available tool",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        // First add a tool
        let block = chain.mineBlock([
            Tx.contractCall('tool-rental', 'add-tool', [
                types.uint(1),
                types.ascii("Power Drill"),
                types.uint(100)
            ], deployer.address)
        ]);
        
        // Then try to rent it
        let rentBlock = chain.mineBlock([
            Tx.contractCall('tool-rental', 'rent-tool', [
                types.uint(1)
            ], user1.address)
        ]);
        
        assertEquals(rentBlock.receipts[0].result.expectOk(), true);
    }
});

Clarinet.test({
    name: "Can return a rented tool",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        // Setup: Add and rent a tool
        let setupBlock = chain.mineBlock([
            Tx.contractCall('tool-rental', 'add-tool', [
                types.uint(1),
                types.ascii("Power Drill"),
                types.uint(100)
            ], deployer.address),
            Tx.contractCall('tool-rental', 'rent-tool', [
                types.uint(1)
            ], user1.address)
        ]);
        
        // Return the tool
        let returnBlock = chain.mineBlock([
            Tx.contractCall('tool-rental', 'return-tool', [
                types.uint(1)
            ], user1.address)
        ]);
        
        assertEquals(returnBlock.receipts[0].result.expectOk(), true);
    }
});
