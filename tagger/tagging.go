package main

import (
	"fmt"
	"log"
	"os"
	"strings"
)

func retagImage(imageFullName, sourceTag, targetTag string) error {
	imageNameParts := strings.Split(imageFullName, "/")
	if len(imageNameParts) != 3 {
		return fmt.Errorf("Incorrect image full name '%s'", imageFullName)
	}

	// registry := imageNameParts[0]
	org := imageNameParts[1]
	image := imageNameParts[2]

	var token string
	if org == "experimentalplatform" {
		token = os.Getenv("TOKEN_PLATFORM")
	} else if org == "protonetinc" {
		token = os.Getenv("TOKEN_PROTONET")
	} else {
		return fmt.Errorf("Unknown image org '%s'", org)
	}

	id, err := getTagImage(image, org, sourceTag, token)
	if err != nil {
		return err
	}

	return setTagImage(image, org, targetTag, id, token)
}

func retagAll(images map[string]string, sourceTag, targetTag string) error {
	type response struct {
		Image string
		Error error
	}

	count := len(images)
	channel := make(chan response)

	for k := range images {
		imageFullName := k
		go func() {
			err := retagImage(imageFullName, sourceTag, targetTag)
			channel <- response{Image: imageFullName, Error: err}
		}()
	}

	for i := 0; i < count; i++ {
		resp := <-channel
		if resp.Error == nil {
			log.Printf("Image '%s': SUCCESS", resp.Image)
		} else {
			log.Printf("Image '%s': ERROR: %s", resp.Image, resp.Error.Error())
			return resp.Error
		}
	}

	return nil
}
