package main

import (
	"bufio"
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"strings"
	"time"
)

// /////////////////	Fonctions /////////////////////////////////////////////
// générer
func randMatrice(lignes, colonnes int) [][]int {
	rand.Seed(time.Now().UnixNano())
	matrice := make([][]int, lignes)
	for i := range matrice {
		matrice[i] = make([]int, colonnes)
		for j := range matrice[i] {
			matrice[i][j] = rand.Intn(10)
		}
	}
	time.Sleep(100 * time.Millisecond)
	return matrice
}

// extraire la matrice fichier texte
func readMatfromFile(filename string) [][]int {
	file, err := os.Open(filename)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	var matrice [][]int
	for scanner.Scan() {
		line := scanner.Text()
		var ligne []int
		for _, value := range strings.Split(line, " ") {
			num, err := strconv.Atoi(value)
			if err != nil {
				panic(err)
			}
			ligne = append(ligne, num)
		}
		matrice = append(matrice, ligne)
	}
	return matrice
}

//multiplication de 2 matrices

func multiply(A, B [][]int, resChannel chan [][]int) {
	lignesA := len(A)
	colonnesA := len(A[0])
	colonnesB := len(B[0])

	resultat := make([][]int, lignesA)
	for i := range resultat {
		resultat[i] = make([]int, colonnesB)
	}

	for i := 0; i < lignesA; i++ {
		for j := 0; j < colonnesB; j++ {
			sum := 0
			for k := 0; k < colonnesA; k++ {
				sum += A[i][k] * B[k][j]
			}
			resultat[i][j] = sum
		}
	}
	resChannel <- resultat
}

// /////////////////	Main  /////////////////////////////////////////////

func main() {
	resChannel := make(chan [][]int)
	nbgoroutines := 10
	for w := 1; w <= nbgoroutines; w++ {
		matA := readMatfromFile("matA.txt")
		matB := randMatrice(3, 3)
		go multiply(matA, matB, resChannel)
	}

	for i := 0; i < nbgoroutines; i++ {
		resultat := <-resChannel
		fmt.Println("Resulat:", resultat)

	}
}
