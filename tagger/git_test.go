package main

import (
	"fmt"
	"io/ioutil"
	"math/rand"
	"os"
	"os/exec"
	"strings"
	"testing"
)

func TestPrepareRepo(t *testing.T) {
	dir, err := prepareRepo()
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	info, err := os.Stat(dir)
	if err != nil {
		if os.IsNotExist(err) {
			t.Fatalf("Directory '%s' does not exist!", dir)
		} else {
			t.Fatal(err)
		}
	}

	if !info.IsDir() {
		t.Fatalf("'%s' is not a directory!", dir)
	}

	gitDir := dir + "/.git"

	info2, err := os.Stat(gitDir)
	if err != nil {
		if os.IsNotExist(err) {
			t.Fatalf("Directory '%s' does not exist!", gitDir)
		} else {
			t.Fatal(err)
		}
	}

	if !info2.IsDir() {
		t.Fatalf("'%s' is not a directory!", gitDir)
	}
}

func TestAddAndCommit(t *testing.T) {
	dir, err := prepareRepo()
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	cmd1 := exec.Command("git", "-C", dir, "show-ref", "refs/heads/master")
	out1, err := cmd1.CombinedOutput()
	if err != nil {
		t.Fatal(err)
	}
	ref1 := strings.Split(string(out1), " ")[0]

	r := make([]byte, 64)
	_, err = rand.Read(r)
	if err != nil {
		t.Fatal(err)
	}
	randomData := fmt.Sprintf("%x", r)

	ioutil.WriteFile(dir+"/"+randomData, []byte(randomData), 0644)

	err = addAndCommit(dir, randomData, "foobar commit")

	cmd2 := exec.Command("git", "-C", dir, "show-ref", "refs/heads/master")
	out2, err := cmd2.CombinedOutput()
	if err != nil {
		t.Fatal(err)
	}
	ref2 := strings.Split(string(out2), " ")[0]

	if ref1 == ref2 {
		t.Fatalf("Repository's master ref should have changed, remains '%s' instead", ref1)
	}

	_, err = os.Stat(dir + "/" + randomData)
	if err != nil {
		if os.IsNotExist(err) {
			t.Fatalf("File '%s' does not exist", dir+"/"+randomData)
		} else {
			t.Fatal(err)
		}
	}
}
