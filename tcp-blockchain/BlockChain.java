import java.util.ArrayList;
import java.util.Scanner;
import java.sql.Timestamp;
import java.security.MessageDigest;

public class BlockChain {
    ArrayList<Block> chain;
    String chainHash;
    int hashesPerSecond;

    public BlockChain() {
        chain = new ArrayList<Block>();
        chainHash = "";
        hashesPerSecond = 0;
        computeHashesPerSecond();
    }

    public void computeHashesPerSecond() {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            String input = "00000000";
            int iterations = 2000000;
            long startTime = System.currentTimeMillis();
            for (int i = 0; i < iterations; i++) {
                digest.digest(input.getBytes("UTF-8"));
            }
            long endTime = System.currentTimeMillis();
            double seconds = (endTime - startTime) / 1000.0;
            if (seconds > 0) {
                hashesPerSecond = (int)(iterations / seconds);
            } else {
                hashesPerSecond = iterations;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public int getChainSize() {
        return chain.size();
    }

    public String getChainHash() {
        return chainHash;
    }

    public int getHashesPerSecond() {
        return hashesPerSecond;
    }

    public Block getLatestBlock() {
        if (chain.isEmpty())
            return null;
        return chain.getLast();
    }

    public void addBlock(Block newBlock) {
        if (!chain.isEmpty()) {
            newBlock.setPreviousHash(chainHash);
        }
        long startTime = System.currentTimeMillis();
        String hash = newBlock.proofOfWork();
        long endTime = System.currentTimeMillis();
        chainHash = hash;
        chain.add(newBlock);
        System.out.println("Total execution time to add this block was " + (endTime - startTime) + " milliseconds");
    }

    public Block getBlock(int i) {
        if (i >= 0 && i < chain.size()) {
            return chain.get(i);
        }
        return null;
    }

    public int getTotalDifficulty() {
        int total = 0;
        for (Block b : chain) {
            total += b.getDifficulty();
        }
        return total;
    }

    public double getTotalExpectedHashes() {
        double total = 0;
        for (Block b : chain) {
            total += Math.pow(16, b.getDifficulty());
        }
        return total;
    }

    public String isChainValid() {
        if (chain.size() == 1) {
            Block genesis = chain.getFirst();
            String genesisHash = genesis.calculateHash();
            String target = new String(new char[genesis.getDifficulty()]).replace('\0', '0');
            if (!genesisHash.startsWith(target)) {
                return "FALSE\nImproper hash on node 0 Does not begin with " + target;
            }
            if (!chainHash.equals(genesisHash)) {
                return "FALSE\nChain hash does not match genesis block hash";
            }
            return "TRUE";
        }

        for (int i = 1; i < chain.size(); i++) {
            Block previous = chain.get(i - 1);
            Block current = chain.get(i);

            String computedPrevHash = previous.calculateHash();
            if (!current.getPreviousHash().equals(computedPrevHash)) {
                return "FALSE\nImproper hash on node " + i + " (hash pointer mismatch)";
            }

            String currentHash = current.calculateHash();
            String target = new String(new char[current.getDifficulty()]).replace('\0', '0');
            if (!currentHash.startsWith(target)) {
                return "FALSE\nImproper hash on node " + i + " Does not begin with " + target;
            }
        }

        Block lastBlock = chain.getLast();
        String lastHash = lastBlock.calculateHash();
        if (!chainHash.equals(lastHash)) {
            return "FALSE\nChain hash does not match last block hash";
        }

        return "TRUE";
    }

    public void repairChain() {
        long startTime = System.currentTimeMillis();
        for (int i = 0; i < chain.size(); i++) {
            Block current = chain.get(i);
            if (i == 0) {
                String hash = current.calculateHash();
                String target = new String(new char[current.getDifficulty()]).replace('\0', '0');
                if (!hash.substring(0, current.getDifficulty()).equals(target)) {
                    current.proofOfWork();
                }
            } else {
                Block previous = chain.get(i - 1);
                current.setPreviousHash(previous.calculateHash());
                String hash = current.calculateHash();
                String target = new String(new char[current.getDifficulty()]).replace('\0', '0');
                if (!hash.substring(0, current.getDifficulty()).equals(target)) {
                    current.proofOfWork();
                }
            }
            chainHash = current.calculateHash();
        }
        long endTime = System.currentTimeMillis();
        System.out.println("Total execution time required to repair the chain was " + (endTime - startTime) + " milliseconds");
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("{\"ds_chain\" : [ ");
        for (int i = 0; i < chain.size(); i++) {
            sb.append(chain.get(i).toString());
            if (i < chain.size() - 1) {
                sb.append(",\n");
            }
        }
        sb.append(" ], \"chainHash\":\"" + chainHash + "\"}");
        return sb.toString();
    }

    public Timestamp getTime() {
        return new Timestamp(System.currentTimeMillis());
    }

    public static void main(String[] args) {
        BlockChain blockchain = new BlockChain();
        Scanner scanner = new Scanner(System.in);

        Block genesis = new Block(0, blockchain.getTime(), "Genesis", 2);

        genesis.proofOfWork();
        blockchain.chain.add(genesis);
        blockchain.chainHash = genesis.calculateHash();

        boolean exit = false;
        while (!exit) {
            System.out.println("0. View basic blockchain status.");
            System.out.println("1. Add a transaction to the blockchain.");
            System.out.println("2. Verify the blockchain.");
            System.out.println("3. View the blockchain.");
            System.out.println("4. Corrupt the chain.");
            System.out.println("5. Hide the corruption by recomputing hashes.");
            System.out.println("6. Exit");

            int choice = scanner.nextInt();
            scanner.nextLine();

            switch(choice) {
                case 0:
                    System.out.println("Current size of chain: " + blockchain.getChainSize());
                    System.out.println("Difficulty of most recent block: " + blockchain.getLatestBlock().getDifficulty());
                    System.out.println("Total difficulty for all blocks: " + blockchain.getTotalDifficulty());
                    System.out.println("Experimented with 2,000,000 hashes.");
                    System.out.println("Approximate hashes per second on this machine: " + blockchain.getHashesPerSecond());
                    System.out.printf("Expected total hashes required for the whole chain: %.6f\n", blockchain.getTotalExpectedHashes());
                    System.out.println("Nonce for most recent block: " + blockchain.getLatestBlock().getNonce());
                    System.out.println("Chain hash: " + blockchain.getChainHash());
                    break;
                case 1:
                    System.out.println("Enter difficulty > 1");
                    int difficulty = scanner.nextInt();
                    scanner.nextLine();
                    System.out.println("Enter transaction");
                    String data = scanner.nextLine();
                    int index = blockchain.getChainSize();
                    Block newBlock = new Block(index, blockchain.getTime(), data, difficulty);
                    blockchain.addBlock(newBlock);
                    break;
                case 2:
                    System.out.println("Verifying entire chain");
                    long startTime = System.currentTimeMillis();
                    String result = blockchain.isChainValid();
                    long endTime = System.currentTimeMillis();
                    System.out.println("Chain verification: " + result +
                            "\nTotal execution time required to verify the chain was " + (endTime - startTime) + " milliseconds");
                    break;
                case 3:
                    System.out.println("View the Blockchain");
                    System.out.println(blockchain);
                    break;
                case 4:
                    System.out.println("Corrupt the Blockchain");
                    System.out.println("Enter block ID of block to corrupt");
                    int blockID = scanner.nextInt();
                    scanner.nextLine();
                    System.out.println("Enter new data for block " + blockID);
                    String newData = scanner.nextLine();
                    Block blockToCorrupt = blockchain.getBlock(blockID);
                    if (blockToCorrupt != null) {
                        blockToCorrupt.setData(newData);
                        System.out.println("Block " + blockID + " now holds " + newData);
                    } else {
                        System.out.println("Block not found.");
                    }
                    break;
                case 5:
                    System.out.println("Repairing the entire chain");
                    blockchain.repairChain();
                    break;
                case 6:
                    exit = true;
                    break;
                default:
                    System.out.println("Invalid option");
            }
        }
        scanner.close();
    }
}
