#include <stdio.h>
#include <stdlib.h>

typedef struct {
    double weight;
    int start;
    int end;
    int label;
} Edge;

int compareEdges(const void *a, const void *b) {
    const Edge *ea = (const Edge *)a;
    const Edge *eb = (const Edge *)b;
    if (ea->weight < eb->weight)
        return -1;
    else if (ea->weight > eb->weight)
        return 1;
    else
        return 0;
}

int find(int parent[], int x) {
    if (parent[x] != x)
        parent[x] = find(parent, parent[x]);
    return parent[x];
}

void unionSets(int parent[], int x, int y) {
    int rootX = find(parent, x);
    int rootY = find(parent, y);
    parent[rootX] = rootY;
}

int isSameSet(int parent[], int x, int y) {
    return find(parent, x) == find(parent, y);
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s input_filename output_filename\n", argv[0]);
        return 1;
    }
    FILE *inputFile = fopen(argv[1], "r");
    if (inputFile == NULL) {
        perror("Error opening input file");
        return 1;
    }
    int n, m;
    if (fscanf(inputFile, "%d", &n) != 1) {
        fprintf(stderr, "Error reading number of nodes\n");
        fclose(inputFile);
        return 1;
    }
    if (fscanf(inputFile, "%d", &m) != 1) {
        fprintf(stderr, "Error reading number of edges\n");
        fclose(inputFile);
        return 1;
    }
    Edge *edges = (Edge *)malloc(m * sizeof(Edge));
    if (edges == NULL) {
        fprintf(stderr, "Memory allocation error\n");
        fclose(inputFile);
        return 1;
    }
    for (int i = 0; i < m; i++) {
        int start, end;
        double weight;
        if (fscanf(inputFile, "%d %d %lf", &start, &end, &weight) != 3) {
            fprintf(stderr, "Error reading edge %d\n", i + 1);
            free(edges);
            fclose(inputFile);
            return 1;
        }
        edges[i].start = start;
        edges[i].end = end;
        edges[i].weight = weight;
        edges[i].label = i + 1;
    }
    fclose(inputFile);
    qsort(edges, m, sizeof(Edge), compareEdges);
    int *parent = (int *)malloc((n + 1) * sizeof(int));
    if (parent == NULL) {
        fprintf(stderr, "Memory allocation error\n");
        free(edges);
        return 1;
    }
    for (int i = 0; i <= n; i++) {
        parent[i] = i;
    }
    FILE *outputFile = fopen(argv[2], "w");
    if (outputFile == NULL) {
        perror("Error opening output file");
        free(edges);
        free(parent);
        return 1;
    }
    double total = 0;
    for (int i = 0; i < m; i++) {
        if (isSameSet(parent, edges[i].start, edges[i].end))
            continue;
        unionSets(parent, edges[i].start, edges[i].end);
        total += edges[i].weight;
        fprintf(outputFile, "%4d: (%d, %d) %.1f\n", edges[i].label, edges[i].start, edges[i].end, edges[i].weight);
    }
    fprintf(outputFile, "Total Weight = %.2f\n", total);
    fclose(outputFile);
    free(edges);
    free(parent);
    return 0;
}
