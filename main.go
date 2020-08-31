package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"regexp"
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
	// Cap the number of frames to append
	// at 60.
	if frames > 60 {
		frames = 60
	}
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

var allLettersRe = regexp.MustCompile(`^[a-zA-Z0-9]+$`)

func main() {
	client := twitch.NewAnonymousClient()
	fp := os.Getenv("QUEUE_FILE_PATH")
	client.Join("large__data__bank")
	processMessage := func(message twitch.PrivateMessage) {
		// The syntax of messages that this program listens to is
		// <buttonstring> <frames>
		// where buttonstring contains a bunch of SNES buttons to hold down
		// and frames is an integer containing the number of frames to
		// advance with those buttons held
		m := message.Message
		words := strings.Split(m, " ")
		if len(words) == 1 {
			if words[0] == "rewind" {
				appendCommand(fp, "rewind", 0)
			} else if frames, err := strconv.Atoi(words[0]); err == nil {
				// If we had just 1 command and it was a number, interpret it as just wait n frames.

				appendCommand(fp, " ", frames)
			}
		}
		if len(words) != 2 {
			return
		}
		cmd := strings.ToLower(words[0])
		if cmd == "save" || cmd == "load" {
			savename := words[1]
			if allLettersRe.MatchString(savename) {
				appendCommand(fp, fmt.Sprintf("%s %s", cmd, savename), 0)
			}

			return
		}
		frames, err := strconv.Atoi(words[1])
		if err != nil {
			return
		}
		for _, c := range cmd {
			switch c {
			case 'a', 'b', 'x', 'y', 'u', 'd', 'l', 'r', '+', '-':
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
