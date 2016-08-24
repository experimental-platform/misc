package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"time"

	"github.com/jessevdk/go-flags"
)

func loadImageList(jsonFilePath string) (buildsData, error) {
	var builds buildsData
	rawData, err := ioutil.ReadFile(jsonFilePath)
	if err != nil {
		return nil, err
	}

	err = json.Unmarshal(rawData, &builds)
	if err != nil {
		return nil, err
	}

	return builds, nil
}

func checkIfTokensPresent() {
	if len(os.Getenv("TOKEN_PLATFORM")) == 0 {
		log.Fatal("TOKEN_PLATFORM is not set")
	}

	if len(os.Getenv("TOKEN_PROTONET")) == 0 {
		log.Fatal("TOKEN_PROTONET is not set")
	}
}

func updateJSON(dir, releaseNotesURL, tagTimestamp, isoTimestamp, targetChannel string, newBuildNumber int32, oldBuilds buildsData, commit bool) error {
	newBuilds := []buildsDatum{oldBuilds[0]}
	newBuilds[0].Build = newBuildNumber
	newBuilds[0].PublishedAt = isoTimestamp
	newBuilds[0].URL = releaseNotesURL

	for k := range newBuilds[0].Images {
		newBuilds[0].Images[k] = tagTimestamp
	}

	log.Printf("Old build version: %d", oldBuilds[0].Build)
	log.Printf("New build version: %d", newBuilds[0].Build)

	data, err := json.MarshalIndent(&newBuilds, "", "  ")
	if err != nil {
		return err
	}

	if commit == true {
		jsonFilePath := fmt.Sprintf("%s/%s.json", dir, targetChannel)
		jsonFileName := fmt.Sprintf("%s.json", targetChannel)
		err = ioutil.WriteFile(jsonFilePath, data, 0644)
		if err != nil {
			return err
		}

		commitMessage := fmt.Sprintf("release on channel '%s' at %s", targetChannel, isoTimestamp)
		err := addAndCommit(dir, jsonFileName, commitMessage)
		if err != nil {
			return err
		}

		err = pushRepo(dir)
		if err != nil {
			return err
		}
		log.Println("Push successful")
	} else {
		log.Printf("New JSON:\n%s\n", string(data))
	}

	return nil
}

func main() {
	var opts struct {
		Commit    bool   `short:"c" long:"commit" description:"Commit the changes. Will make a dry run without this flag."`
		Build     int32  `short:"b" long:"build" required:"true" description:"Specify the build number to be placed inside the JSON."`
		SourceTag string `short:"s" long:"source-tag" default:"development" description:"Registry tag to be retagging from."`
		TargetTag string `short:"t" long:"target-tag" default:"soul3" description:"Registry tag to be retagging to."`
		URL       string `short:"u" long:"url" required:"true" description:"Release notes URL"`
	}

	_, err := flags.Parse(&opts)
	if err != nil {
		os.Exit(1)
	}

	currentTime := time.Now().UTC()
	tagTimestamp := currentTime.Format("2006-01-02-1504")
	isoTimestamp := currentTime.Format("2006-01-02T15:04:05Z")

	dir, err := prepareRepo()
	if err != nil {
		log.Fatalf("Failed to clone the builds repo: %s", err.Error())
	}
	log.Printf("Working in directory '%s'", dir)
	defer os.RemoveAll(dir)

	jsonFilePath := fmt.Sprintf("%s/%s.json", dir, opts.SourceTag)
	builds, err := loadImageList(jsonFilePath)
	if err != nil {
		log.Fatalf("Failed to load build data from '%s'", jsonFilePath)
	}

	fmt.Printf("Tag timestamp: %s\n", tagTimestamp)
	fmt.Printf("ISO timestamp: %s\n", isoTimestamp)

	if opts.Commit == true {
		checkIfTokensPresent()

		err := retagAll(builds[0].Images, opts.SourceTag, tagTimestamp)
		if err != nil {
			log.Fatal(err)
		}
	} else {
		log.Printf("Dry run. Would otherwise retag following images from '%s' to '%s' and update channel '%s':\n", opts.SourceTag, tagTimestamp, opts.TargetTag)
		for k := range builds[0].Images {
			log.Printf(" * %s\n", k)
		}
	}

	err = updateJSON(dir, opts.URL, tagTimestamp, isoTimestamp, opts.TargetTag, opts.Build, builds, opts.Commit)
	if err != nil {
		log.Fatal(err)
	}
}
