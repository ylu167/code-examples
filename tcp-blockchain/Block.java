import java.math.BigInteger;
import java.sql.Timestamp;
import java.security.MessageDigest;

public class Block {
    private int index;
    private Timestamp timestamp;
    private String data;
    private String previousHash;
    private BigInteger nonce;
    private int difficulty;

    public Block(int index, Timestamp timestamp, String data, int difficulty) {
        this.index = index;
        this.timestamp = timestamp;
        this.data = data;
        this.difficulty = difficulty;
        this.previousHash = "";
        this.nonce = BigInteger.ZERO;
    }

    public int getIndex() { return index; }
    public void setIndex(int index) { this.index = index; }

    public Timestamp getTimestamp() { return timestamp; }
    public void setTimestamp(Timestamp timestamp) { this.timestamp = timestamp; }

    public String getData() { return data; }
    public void setData(String data) { this.data = data; }

    public String getPreviousHash() { return previousHash; }
    public void setPreviousHash(String previousHash) { this.previousHash = previousHash; }

    public BigInteger getNonce() { return nonce; }

    public int getDifficulty() { return difficulty; }
    public void setDifficulty(int difficulty) { this.difficulty = difficulty; }

    public String calculateHash() {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            String input = index + timestamp.toString() + data + previousHash + nonce.toString() + difficulty;
            byte[] hashBytes = digest.digest(input.getBytes("UTF-8"));

            StringBuilder hexString = new StringBuilder();
            for (byte hashByte : hashBytes) {
                String hex = Integer.toHexString(0xff & hashByte);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString().toUpperCase();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public String proofOfWork() {
        String hash = calculateHash();
        String target = new String(new char[difficulty]).replace('\0', '0');
        while (!hash.substring(0, difficulty).equals(target)) {
            nonce = nonce.add(BigInteger.ONE);
            hash = calculateHash();
        }
        return hash;
    }

    @Override
    public String toString() {
        return "{\"index\" : " + index +
                ",\"time stamp \" : \"" + timestamp.toString() + "\"" +
                ",\"Tx \" : \"" + data + "\"" +
                ",\"PrevHash\" : \"" + previousHash + "\"" +
                ",\"nonce\" : " + nonce +
                ",\"difficulty\": " + difficulty + "}";
    }

    public static void main(String[] args) {
        Block block = new Block(0, new Timestamp(System.currentTimeMillis()), "Genesis", 2);
        String hash = block.proofOfWork();
        System.out.println("Block hash: " + hash);
    }
}
