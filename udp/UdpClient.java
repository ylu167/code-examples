import java.net.*;
import java.io.*;
import java.util.Scanner;
import java.nio.ByteBuffer;

public class UdpClient {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        System.out.println("The UDP client is running.");
        System.out.println("Enter server port number: ");
        int serverPort = scanner.nextInt();
        scanner.nextLine();

        while (true) {
            System.out.println("\n1. Add a value to your sum.");
            System.out.println("2. Subtract a value from your sum.");
            System.out.println("3. Get your sum.");
            System.out.println("4. Exit client.");

            int choice = 0;
            try {
                choice = Integer.parseInt(scanner.nextLine());
            } catch(NumberFormatException e) {
                System.out.println("Invalid option. Please enter an integer between 1 and 4.");
                continue;
            }

            if (choice == 4) {
                System.out.println("Client side quitting. The server is still running.");
                break;
            }

            int value = 0;
            if (choice == 1) {
                System.out.println("Enter value to add:");
                try {
                    value = Integer.parseInt(scanner.nextLine());
                } catch(NumberFormatException e) {
                    System.out.println("Invalid option. Please enter an integer between 1 and 4.");
                    continue;
                }
            }
            else if (choice == 2) {
                System.out.println("Enter value to subtract:");
                try {
                    value = Integer.parseInt(scanner.nextLine());
                } catch(NumberFormatException e) {
                    System.out.println("Invalid option. Please enter an integer between 1 and 4.");
                    continue;
                }
            }
            else if (choice == 3) {
            }
            else {
                System.out.println("Invalid option. Please enter an integer between 1 and 4.");
                continue;
            }

            System.out.println("Enter your ID:");
            int id = 0;
            try {
                id = Integer.parseInt(scanner.nextLine());
            } catch(NumberFormatException e) {
                System.out.println("Invalid ID. Please enter an integer between 0 and 999.");
                continue;
            }
            if (id < 0 || id > 999) {
                System.out.println("ID must be between 0 and 999.");
                continue;
            }

            int result = sendRequest(id, choice, value, serverPort);
            System.out.println("The result is " + result + ".");
        }
        scanner.close();
    }

    public static int sendRequest(int id, int opCode, int value, int serverPort) {
        DatagramSocket socket = null;
        int result = 0;
        try {
            socket = new DatagramSocket();
            InetAddress serverAddress = InetAddress.getByName("localhost");

            ByteBuffer buffer = ByteBuffer.allocate(12);
            buffer.putInt(id);
            buffer.putInt(opCode);
            buffer.putInt(value);
            byte[] data = buffer.array();

            DatagramPacket request = new DatagramPacket(data, data.length, serverAddress, serverPort);
            socket.send(request);

            byte[] recvBuffer = new byte[4];
            DatagramPacket reply = new DatagramPacket(recvBuffer, recvBuffer.length);
            socket.receive(reply);
            result = ByteBuffer.wrap(reply.getData()).getInt();
        }
        catch (SocketException e) {
            System.out.println("Socket Exception: " + e.getMessage());
        }
        catch (IOException e) {
            System.out.println("IO Exception: " + e.getMessage());
        }
        finally {
            if (socket != null) {
                socket.close();
            }
        }
        return result;
    }
}
