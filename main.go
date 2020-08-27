package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"

	"github.com/gempir/go-twitch-irc/v2"
)

func getLastTimestamp(path string) int {
	file, err := os.Open(path)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	var id int
	for scanner.Scan() {
		fmt.Println(scanner.Text())
		words := strings.Split(scanner.Text(), " ")
		var err error
		id, err = strconv.Atoi(words[0])
		if err != nil {
			log.Fatal(err)
		}
	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}
	return id
}

func appendCommand(fp string, command string, frames int) {
	f, err := os.OpenFile(fp,
		os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()
	if _, err := fmt.Fprintf(f, "%s %d\n", command, frames); err != nil {
		log.Fatal(err)
	}
}

func main() {
	client := twitch.NewAnonymousClient()
	fp := os.Getenv("QUEUE_FILE_PATH")
	client.Join("twitchassistedspeedrun")
	processMessage := func(message twitch.PrivateMessage) {
		m := message.Message
		words := strings.Split(m, " ")
		if len(words) != 2 {
			return
		}
		frames, err := strconv.Atoi(words[1])
		if err != nil {
			return
		}
		cmd := strings.ToLower(words[0])
		for _, c := range cmd{
			switch c {
			case 'a', 'b', 'x', 'y', 'u', 'd', 'l', 'r':
			default:
				return
			}
		}
		appendCommand(fp, cmd, frames)
	}
	client.OnPrivateMessage(processMessage)
	if err := client.Connect(); err != nil {
		log.Fatal(err)
	}
}
