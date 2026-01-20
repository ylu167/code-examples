public class Response {
    private String response;
    private int numBlocks;

    public Response() {}

    public Response(String response, int numBlocks) {
        this.response = response;
        this.numBlocks = numBlocks;
    }

    public String getResponse() {
        return response;
    }
    public void setResponse(String response) {
        this.response = response;
    }

    public int getNumBlocks() {
        return numBlocks;
    }
    public void setNumBlocks(int numBlocks) {
        this.numBlocks = numBlocks;
    }
}
