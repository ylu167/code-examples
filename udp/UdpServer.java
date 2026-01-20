import java.net.*;
import java.io.*;
import java.util.TreeMap;
import java.util.Scanner;
import java.nio.ByteBuffer;

public class UdpServer {
    public static void main(String[] args) {
        DatagramSocket socket = null;
        Scanner scanner = new Scanner(System.in);
        TreeMap<Integer, Integer> idSumMap = new TreeMap<>();

        System.out.println("The UDP server is running.");
        System.out.println("Enter server port number: ");
        int port = scanner.nextInt();
        scanner.nextLine();

        try {
            socket = new DatagramSocket(port);
            while (true) {
                byte[] buffer = new byte[12];
                DatagramPacket request = new DatagramPacket(buffer, buffer.length);
                socket.receive(request);
                ByteBuffer receivedBuffer = ByteBuffer.wrap(request.getData());
                int id = receivedBuffer.getInt();
                int opCode = receivedBuffer.getInt();
                int value = receivedBuffer.getInt();

                int newSum = processOperation(idSumMap, id, opCode, value);
                byte[] responseBytes = ByteBuffer.allocate(4).putInt(newSum).array();
                DatagramPacket reply = new DatagramPacket(responseBytes, responseBytes.length, request.getAddress(), request.getPort());
                socket.send(reply);
            }
        } catch (SocketException e) {
            System.out.println("Socket Exception: " + e.getMessage());
        } catch (IOException e) {
            System.out.println("IO Exception: " + e.getMessage());
        } finally {
            if (socket != null) {
                socket.close();
            }
            scanner.close();
        }
    }

    public static int processOperation(TreeMap<Integer, Integer> idSumMap, int id, int opCode, int value) {
        if (!idSumMap.containsKey(id)) {
            idSumMap.put(id, 0);
        }
        int currentSum = idSumMap.get(id);
        int newSum = currentSum;
        if (opCode == 1) {
            System.out.println("Adding: " + value + " to " + currentSum + " for ID " + id);
            newSum = currentSum + value;
            idSumMap.put(id, newSum);
        } else if (opCode == 2) {
            System.out.println("Subtracting: " + value + " from " + currentSum + " for ID " + id);
            newSum = currentSum - value;
            idSumMap.put(id, newSum);
        } else if (opCode == 3) {
            System.out.println("Getting sum for ID " + id + ". Current sum is " + currentSum);
            newSum = currentSum;
        } else {
            System.out.println("Invalid operation code received: " + opCode);
        }
        System.out.println("Returning sum of " + newSum + " to client for ID " + id);
        return newSum;
    }
}
