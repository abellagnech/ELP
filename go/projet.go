package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

// ** Main ** //

func main() {

	// Création des 2 channels pour la synchro des goroutines
	procChannel := make(chan Matrix)
	resChannel := make(chan MatrixRes)

	// Création des goroutines
	nbgoroutines := 10
	for w := 1; w <= nbgoroutines; w++ {
		go worker(w, procChannel, resChannel)
	}

	// Envoyer les matrices au channel procChannel
	nbTasks := 10
	for i := 0; i < nbTasks; i++ {
		matrix1 := readMatrix("matA.txt")
		matrix2 := readMatrix("matB.txt")
		procChannel <- matrix1
		procChannel <- matrix2
	}
	close(procChannel)
	var errOccurred bool
	for i := 0; i < nbTasks; i++ {
		res := <-resChannel
		if res.err != nil {
			fmt.Println(res.err)
			errOccurred = true
		} else if !errOccurred {
			fmt.Println(res.result.Data)
		}
	}
}

/*-----------------------------------------------*/
// ** STRUCTURES  ** //

// //////////////////////////////////////////// La structure d'une Matrice :
type Matrix struct {
	Lignes   int
	Colonnes int
	Data     [][]int
}

// /////////////////////////////////////////// La structure d'un résultat de multiplication de matrices
type MatrixRes struct {
	result Matrix
	err    error
}

// ** FONCTIONS ** //
// ///////////////////////////fonction qui lit une matrice à partir d'un fichier
func readMatrix(filename string) Matrix {
	file, err := os.Open(filename)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	var matrix [][]int
	var count2 int
	var count1 int
	for scanner.Scan() {
		line := scanner.Text()
		var row []int
		for _, value := range strings.Split(line, " ") {
			num, err := strconv.Atoi(value)
			if err != nil {
				panic(err)
			}
			row = append(row, num)
			count1++
		}
		matrix = append(matrix, row)
		count2++
	}
	return Matrix{Lignes: count2, Colonnes: 3, Data: matrix}

}

// ////////////////////////////////////////////La fonction qui multiplie deux matrices
func multiplyMatrix(matrix1 Matrix, matrix2 Matrix) (Matrix, error) {

	// Vérifier si le produit est possible
	if matrix1.Colonnes != matrix2.Lignes {
		return Matrix{}, fmt.Errorf("Multiplication impossible")
	}

	// Création de la matrice résultat
	result := Matrix{Lignes: matrix1.Lignes, Colonnes: matrix2.Colonnes}
	result.Data = make([][]int, matrix1.Lignes)
	for i := range result.Data {
		result.Data[i] = make([]int, matrix2.Colonnes)
	}

	// Calcul de la matrice résultat
	for i := 0; i < matrix1.Lignes; i++ {
		for j := 0; j < matrix2.Colonnes; j++ {
			somme := 0
			for k := 0; k < matrix1.Colonnes; k++ {
				somme += matrix1.Data[i][k] * matrix2.Data[k][j]
			}
			result.Data[i][j] = somme
		}
	}

	// Afficher la matrice résultat
	return result, nil

}

// //////////////////////////////////////////// La fonction WORKER (effectue des multiplication en parallèle avec des goroutines)
func worker(id int, procChannel <-chan Matrix, resChannel chan<- MatrixRes) {
	for j := range procChannel {
		matrix1 := j
		matrix2 := <-procChannel
		result, err := multiplyMatrix(matrix1, matrix2)
		if err != nil {
			resChannel <- MatrixRes{result: result, err: err}
		} else {
			resChannel <- MatrixRes{result: result, err: nil}
		}
	}
}
