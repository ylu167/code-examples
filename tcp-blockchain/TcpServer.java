import java.net.*;
import java.io.*;
import java.math.BigInteger;
import java.security.MessageDigest;
import com.google.gson.Gson;

public class TcpServer {
    public static void main(String[] args) {
        BlockChain blockchain = new BlockChain();
        Block genesis = new Block(0, blockchain.getTime(), "Genesis", 2);
        genesis.proofOfWork();
        blockchain.chain.add(genesis);
        blockchain.chainHash = genesis.calculateHash();

        System.out.println("Verifying Blockchain Server running\n");
        Gson gson = new Gson();

        try {
            int serverPort = 7777;
            ServerSocket listenSocket = new ServerSocket(serverPort);

            while (true) {
                Socket clientSocket = listenSocket.accept();
                System.out.println("Visitor connected.");
                try {
                    BufferedReader in = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
                    PrintWriter out = new PrintWriter(new BufferedWriter(new OutputStreamWriter(clientSocket.getOutputStream())));

                    while (true) {
                        String requestJson = in.readLine();
                        if (requestJson == null) break;

                        Request req = gson.fromJson(requestJson, Request.class);

                        String clientId = req.getId();
                        String eStr = req.getE();
                        String nStr = req.getN();
                        String signatureStr = req.getSignature();

                        System.out.println("Client public key:");
                        System.out.println("e = " + eStr);
                        System.out.println("n = " + nStr);

                        BigInteger eBI = new BigInteger(eStr);
                        BigInteger nBI = new BigInteger(nStr);
                        String expectedId = computeClientId(eBI, nBI);
                        boolean idValid = clientId.equals(expectedId);
                        System.out.println("Expected client ID: " + expectedId);
                        System.out.println("Provided client ID: " + clientId);

                        String payload = buildPayload(req);
                        boolean signatureValid = verifySignature(payload, signatureStr, eBI, nBI);
                        System.out.println("Signature verification: " + (signatureValid ? "SUCCESS" : "FAILURE"));

                        String responseText;
                        if (!idValid || !signatureValid) {
                            responseText = "Error in request";
                        } else {
                            long startTime, endTime;
                            switch (req.getOption()) {
                                case 0:
                                    responseText = "Current size of chain: " + blockchain.getChainSize() + "\n" +
                                            "Difficulty of most recent block: " + blockchain.getLatestBlock().getDifficulty() + "\n" +
                                            "Total difficulty for all blocks: " + blockchain.getTotalDifficulty() + "\n" +
                                            "Approximate hashes per second on this machine: " + blockchain.getHashesPerSecond() + "\n" +
                                            String.format("Expected total hashes required for the whole chain: %.6f\n", blockchain.getTotalExpectedHashes()) +
                                            "Nonce for most recent block: " + blockchain.getLatestBlock().getNonce() + "\n" +
                                            "Chain hash: " + blockchain.getChainHash();
                                    break;
                                case 1:
                                    int diff = req.getDifficulty();
                                    String txData = req.getData();
                                    int index = blockchain.getChainSize();
                                    Block newBlock = new Block(index, blockchain.getTime(), txData, diff);
                                    if (blockchain.getChainSize() > 0) {
                                        newBlock.setPreviousHash(blockchain.getChainHash());
                                    }
                                    startTime = System.currentTimeMillis();
                                    String hash = newBlock.proofOfWork();
                                    endTime = System.currentTimeMillis();
                                    blockchain.chainHash = hash;
                                    blockchain.chain.add(newBlock);
                                    responseText = "Total execution time to add this block was " + (endTime - startTime) + " milliseconds";
                                    break;
                                case 2:
                                    startTime = System.currentTimeMillis();
                                    String result = blockchain.isChainValid();
                                    endTime = System.currentTimeMillis();
                                    responseText = "Chain verification: " + result +
                                            "\nTotal execution time required to verify the chain was " + (endTime - startTime) + " milliseconds";
                                    break;
                                case 3:
                                    responseText = blockchain.toString();
                                    break;
                                case 4:
                                    int blockID = req.getBlockID();
                                    String newData = req.getData();
                                    Block blockToCorrupt = blockchain.getBlock(blockID);
                                    if (blockToCorrupt != null) {
                                        blockToCorrupt.setData(newData);
                                        responseText = "Block " + blockID + " now holds " + newData;
                                    } else {
                                        responseText = "Block not found.";
                                    }
                                    break;
                                case 5:
                                    startTime = System.currentTimeMillis();
                                    blockchain.repairChain();
                                    endTime = System.currentTimeMillis();
                                    responseText = "Total execution time required to repair the chain was " + (endTime - startTime) + " milliseconds";
                                    break;
                                case 6:
                                    responseText = "Exiting server connection";
                                    break;
                                default:
                                    responseText = "Invalid option";
                            }
                        }

                        Response resp = new Response(responseText, blockchain.getChainSize());
                        String responseJson = gson.toJson(resp);
                        out.println(responseJson);
                        out.flush();

                        System.out.println("Received JSON request:");
                        System.out.println(requestJson);
                        System.out.println("Sending JSON response:");
                        System.out.println(responseJson);
                        System.out.println("Number of Blocks on Chain == " + blockchain.getChainSize() + ".\n");

                        if (req.getOption() == 6) {
                            break;
                        }
                    }
                    clientSocket.close();
                } catch (Exception ex) {
                    System.out.println("Connection error: " + ex.getMessage());
                }
            }
        } catch (IOException ex) {
            System.out.println("IO Exception: " + ex.getMessage());
        }
    }

    private static String computeClientId(BigInteger e, BigInteger n) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            String keyString = e.toString() + n.toString();
            byte[] hash = md.digest(keyString.getBytes("UTF-8"));
            int len = hash.length;
            byte[] idBytes = new byte[20];
            System.arraycopy(hash, len - 20, idBytes, 0, 20);
            return bytesToHex(idBytes);
        } catch (Exception ex) {
            System.out.println("Error computing client ID: " + ex.getMessage());
            return null;
        }
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for(byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    private static String buildPayload(Request req) {
        String optionStr = Integer.toString(req.getOption());
        String difficultyStr = Integer.toString(req.getDifficulty());
        String blockIDStr = Integer.toString(req.getBlockID());
        String dataStr = (req.getData() == null) ? "" : req.getData();
        return req.getId() + req.getE() + req.getN() + optionStr + difficultyStr + dataStr + blockIDStr;
    }

    private static boolean verifySignature(String payload, String signatureStr, BigInteger e, BigInteger n) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = md.digest(payload.getBytes("UTF-8"));
            BigInteger hashInt = new BigInteger(1, hashBytes);

            BigInteger signatureInt = new BigInteger(signatureStr);
            BigInteger decryptedHash = signatureInt.modPow(e, n);

            return hashInt.equals(decryptedHash);
        } catch (Exception ex) {
            System.out.println("Error verifying signature: " + ex.getMessage());
            return false;
        }
    }
}
