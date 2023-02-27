
import inquirer from 'inquirer';
import { exec } from 'node:child_process';
import psList from 'ps-list';
import readline from 'readline';
//ctrp+P pour sortir du terminal
function key_exit(){
    readline.emitKeypressEvents(process.stdin);
    if (process.stdin.isTTY) process.stdin.setRawMode(true);
    process.stdin.on("keypress", (str, key) => {
    if(key.ctrl && key.name == "p") process.exit()
    })
}
async function execShell() {
    const command = await getCommande();
    execShell();
}
//recup de la commande du prompt 
async function getCommande() {
    const ans = await inquirer.prompt([
        {
            type: 'input',
            name: 'command',

            message: ('>>'),
            prefix : (`user`), 
        },
    ]).then(answers => {
        Commandes(answers.command.split(' '));
    });
    return ans;
}
//fonctions qui gère les commandes rentrées par l'utilisateur
async function Commandes(cmd) {
    switch (cmd[0]) {
        case 'help' :
            console.log("help: lister toutes les commandes et leurs fonctions");
            console.log("lp : lister les processus en cours");
            console.log("exec <PATH> : exécuter un programme avec un chemin absolu");
            console.log("bing <-k|-c|-p> : tuer, reprendre un processus ou mettre en pause");
            console.log("ctrl+P : sortir du shell");
            break;
        case 'lp' :
            let lpliste = (await psList())
            for (let i = 0; i < lpliste.length; i++) {
                console.log((i+1)+ ' ' + lpliste[i].name);
            }
            break;
        case 'exec' :
            exec(cmd[1], (err, stdout) => {
            if (err) {
                console.error(`exec error: ${err}`);
                return;
            }
            console.log(stdout)
            })
            break;
        case 'bing' :
            switch (cmd[1]) {
                case '-k' :
                    exec(`kill ${cmd[2]}`, (err, stdout) => {
                        if (err) {
                            console.error(`Error: ${err}`);
                            return;
                        }
                    });
                    break;
                case'-p' :
                    exec(`kill -STOP ${cmd[2]}`, (err, stdout, stderr) => {
                        if (err) {
                            console.error(`Error: ${err}`);
                            return;
                        }
                    });
                    break;
                case '-c' :
                    exec(`kill -CONT ${cmd[2]}`, (err, stdout, stderr) => {
                        if (err) {
                            console.error(`Error: ${err}`);
                            return;
                        }
                    });
                    break;
                default :
                    console.log("Commande invalide. Syntaxe correcte : bing <-k|-c|-p>");
                    console.log(cmd[1])
                    break;
            }
            break;
        default :
            console.log("Commande inconnue");
    }
}
//executer le terminal
key_exit();
execShell()

