import java.net.*;
import java.io.*;
import java.math.BigInteger;
import java.security.MessageDigest;
import java.util.Random;
import java.util.Scanner;
import com.google.gson.Gson;

public class TcpClient {

    private static BigInteger e;
    private static BigInteger d;
    private static BigInteger n;
    private static String clientId;

    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("Usage: java TcpClient <hostname>");
            return;
        }
        String hostname = args[0];

        generateRSAKeys();

        clientId = computeClientId(e, n);

        System.out.println("RSA Public Key (e, n):");
        System.out.println("e = " + e);
        System.out.println("n = " + n);
        System.out.println("RSA Private Key (d, n):");
        System.out.println("d = " + d);
        System.out.println("n = " + n);
        System.out.println("Client ID (last 20 bytes of SHA-256(e+n)):");
        System.out.println(clientId);

        try {
            int serverPort = 7777;
            Socket clientSocket = new Socket(hostname, serverPort);
            BufferedReader in = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
            PrintWriter out = new PrintWriter(new BufferedWriter(new OutputStreamWriter(clientSocket.getOutputStream())));
            Scanner scanner = new Scanner(System.in);
            Gson gson = new Gson();
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

                Request req = new Request();
                req.setOption(choice);

                switch (choice) {
                    case 0:
                        break;
                    case 1:
                        System.out.println("Enter difficulty > 1:");
                        int difficulty = scanner.nextInt();
                        scanner.nextLine();
                        req.setDifficulty(difficulty);
                        System.out.println("Enter transaction:");
                        String transaction = scanner.nextLine();
                        req.setData(transaction);
                        break;
                    case 2:
                        System.out.println("Verifying entire chain.");
                        break;
                    case 3:
                        System.out.println("Viewing the blockchain.");
                        break;
                    case 4:
                        System.out.println("Corrupt the Blockchain");
                        System.out.println("Enter block ID of block to corrupt:");
                        int blockID = scanner.nextInt();
                        scanner.nextLine();
                        req.setBlockID(blockID);
                        System.out.println("Enter new data for block " + blockID + ":");
                        String newData = scanner.nextLine();
                        req.setData(newData);
                        break;
                    case 5:
                        System.out.println("Repairing the entire chain.");
                        break;
                    case 6:
                        exit = true;
                        break;
                    default:
                        System.out.println("Invalid option.");
                        continue;
                }

                req.setId(clientId);
                req.setE(e.toString());
                req.setN(n.toString());

                String payload = buildPayload(req);
                String signature = signPayload(payload, d, n);
                req.setSignature(signature);

                String requestJson = gson.toJson(req);
                out.println(requestJson);
                out.flush();

                String responseJson = in.readLine();
                Response resp = gson.fromJson(responseJson, Response.class);
                System.out.println("Server response: " + resp.getResponse());
            }

            clientSocket.close();
            scanner.close();
        } catch (IOException ex) {
            System.out.println("IO Exception: " + ex.getMessage());
        }
    }

    private static void generateRSAKeys() {
        try {
            Random rnd = new Random();
            BigInteger p = new BigInteger(400, 100, rnd);
            BigInteger q = new BigInteger(400, 100, rnd);
            n = p.multiply(q);
            BigInteger phi = (p.subtract(BigInteger.ONE)).multiply(q.subtract(BigInteger.ONE));
            e = new BigInteger("65537");
            d = e.modInverse(phi);
        } catch (Exception ex) {
            System.out.println("Error generating RSA keys: " + ex.getMessage());
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

    private static String signPayload(String payload, BigInteger d, BigInteger n) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = md.digest(payload.getBytes("UTF-8"));
            BigInteger hashInt = new BigInteger(1, hashBytes);
            BigInteger signatureInt = hashInt.modPow(d, n);
            return signatureInt.toString();
        } catch (Exception ex) {
            System.out.println("Error signing payload: " + ex.getMessage());
            return null;
        }
    }
}
