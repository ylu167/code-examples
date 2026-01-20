public class Request {
    private int option;
    private int difficulty;
    private String data;
    private int blockID;

    private String id;
    private String e;
    private String n;
    private String signature;

    public Request() {}

    public Request(int option, int difficulty, String data, int blockID, String id, String e, String n, String signature) {
        this.option = option;
        this.difficulty = difficulty;
        this.data = data;
        this.blockID = blockID;
        this.id = id;
        this.e = e;
        this.n = n;
        this.signature = signature;
    }

    public int getOption() { return option; }
    public void setOption(int option) { this.option = option; }
    public int getDifficulty() { return difficulty; }
    public void setDifficulty(int difficulty) { this.difficulty = difficulty; }
    public String getData() { return data; }
    public void setData(String data) { this.data = data; }
    public int getBlockID() { return blockID; }
    public void setBlockID(int blockID) { this.blockID = blockID; }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getE() { return e; }
    public void setE(String e) { this.e = e; }
    public String getN() { return n; }
    public void setN(String n) { this.n = n; }
    public String getSignature() { return signature; }
    public void setSignature(String signature) { this.signature = signature; }
}
