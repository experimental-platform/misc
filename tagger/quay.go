package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
)

type quayTagsResponseTag struct {
	Reversion     bool   `json:"reversion"`
	StartTs       *int32 `json:"start_ts"`
	EndTs         *int32 `json:"end_ts"`
	Name          string `json:"name"`
	DockerImageID string `json:"docker_image_id"`
}

type quayTagsResponse struct {
	HasAdditional bool  `json:"has_additional"`
	Page          int32 `json:"page"`
	Tags          []quayTagsResponseTag
}

type errorQuayTagNotFound struct {
	s string
}

func newErrorQuayTagNotFound(tag, org, image string) *errorQuayTagNotFound {
	return &errorQuayTagNotFound{
		s: fmt.Sprintf("Failed to find tag '%s' for image '%s/%s'", tag, org, image),
	}
}

func (e *errorQuayTagNotFound) Error() string {
	return e.s
}

func getImageTags(image, org, token string) ([]quayTagsResponseTag, error) {
	var results []quayTagsResponseTag

	for page := 1; ; page++ {
		url := fmt.Sprintf("https://quay.io/api/v1/repository/%s/%s/tag/?page=%d", org, image, page)

		req, err := http.NewRequest("GET", url, nil)
		if err != nil {
			return nil, err
		}

		req.Header.Set("Authorization", "Bearer "+token)
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			return nil, err
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			return nil, errors.New(resp.Status)
		}

		var apiResponse quayTagsResponse

		decoder := json.NewDecoder(resp.Body)
		err = decoder.Decode(&apiResponse)
		if err != nil {
			return nil, err
		}

		results = append(results, apiResponse.Tags...)

		if apiResponse.HasAdditional == false {
			break
		}
	}

	return results, nil
}

func getTagImage(image, org, tag, token string) (string, error) {
	tags, err := getImageTags(image, org, token)
	if err != nil {
		return "", nil
	}

	for _, t := range tags {
		if t.EndTs == nil && t.Name == tag {
			return t.DockerImageID, nil
		}
	}

	return "", newErrorQuayTagNotFound(tag, org, image)

}

func setTagImage(image, org, tag, imageID, token string) error {
	url := fmt.Sprintf("https://quay.io/api/v1/repository/%s/%s/tag/%s", org, image, tag)
	var jsonStr = fmt.Sprintf(`{"image":"%s"}`, imageID)

	req, err := http.NewRequest("PUT", url, bytes.NewBuffer([]byte(jsonStr)))
	if err != nil {
		return err
	}

	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 201 {
		return errors.New(resp.Status)
	}

	return nil
}
