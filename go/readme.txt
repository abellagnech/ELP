Ce programme utilise des goroutines pour effectuer la multiplication de matrices de manière parallèle. 
Il fait la multiplication d'une matrice carrée donnée (constante), avec des matrices qu'on génère aléatoirement.
-La fonction randMatrice génère une matrice aléatoire de taille donnée.
-La fonction readMatfromFile extrait une matrice à partir d'un fichier texte.
-La fonction multiply calcule le produit de deux matrices. Elle utilise un canal (resChannel) pour renvoyer le résultat à la fonction principale.
-Dans la fonction principale, on crée un canal (resChannel) et on exécute 10 goroutines, chacune d'entre elles charge une matrice à partir de "matA.txt" et génère une autre matrice aléatoire. Ensuite, chaque goroutine calcule le produit des deux matrices en utilisant la fonction multiply et envoie le résultat à la fonction principale via le canal (resChannel).
-La fonction principale lit le résultat du canal (resChannel) pour chaque goroutine et l'affiche.
Pour éxecuter le programme, il suffit de taper dans le terminal : go run projetProdMat.go