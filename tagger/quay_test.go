package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path"
	"reflect"
	"strings"
	"testing"
)

type RewriteTransport struct {
	Transport http.RoundTripper
	URL       *url.URL
}

func (t RewriteTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	// note that url.URL.ResolveReference doesn't work here
	// since t.u is an absolute url
	req.URL.Scheme = t.URL.Scheme
	req.URL.Host = t.URL.Host
	req.URL.Path = path.Join(t.URL.Path, req.URL.Path)
	rt := t.Transport
	if rt == nil {
		rt = http.DefaultTransport
	}
	return rt.RoundTrip(req)
}

func getMux() *http.ServeMux {
	mux := http.NewServeMux()

	mux.Handle("/api/v1/repository/experimentalplatform/skvs/tag", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == "GET" {
			switch r.FormValue("page") {
			case "1":
				w.WriteHeader(200)
				w.Header().Set("Content-Type", "application/json")
				fmt.Fprintln(w, `{"has_additional": true, "page": 1, "tags": [{"reversion": false, "start_ts": 1470957215, "name": "development", "docker_image_id": "8b8cd46eeab0b530d0fcb64de26fe62fd68e736fc627c526933b680d3ae5291f"}, {"reversion": false, "start_ts": 1470916419, "name": "2016-08-11-1153", "docker_image_id": "9aaca8087e1679dc87c5af02e0f31d451833f73346b0bc99c26d0aef0cb33623"}, {"reversion": false, "end_ts": 1470957215, "start_ts": 1470870876, "name": "development", "docker_image_id": "9aaca8087e1679dc87c5af02e0f31d451833f73346b0bc99c26d0aef0cb33623"}, {"reversion": false, "end_ts": 1470870876, "start_ts": 1470784408, "name": "development", "docker_image_id": "053ee588b007b7b6eba8d574c1365c8435a07cf7210227ed8cac924312faaaf5"}, {"reversion": false, "end_ts": 1470784408, "start_ts": 1470698284, "name": "development", "docker_image_id": "1490454698ce848a5e4c7d7acfe67f0a6ead6f6a9fad672e60994500d96e23cf"}, {"reversion": false, "start_ts": 1470669097, "name": "soul3", "docker_image_id": "fb38f27d3c97e1d23b07100b9cfefe4e91ee5c5373f192ba5033cf31fdbf40fb"}, {"reversion": false, "start_ts": 1470669059, "name": "2016-08-08-1510", "docker_image_id": "fb38f27d3c97e1d23b07100b9cfefe4e91ee5c5373f192ba5033cf31fdbf40fb"}, {"reversion": false, "end_ts": 1470669097, "start_ts": 1470668730, "name": "soul3", "docker_image_id": "1319cc8604ca0cf46cd559632db880594766a1737768ff280e767777eada73bc"}, {"reversion": false, "start_ts": 1470668691, "name": "2016-08-08-1504", "docker_image_id": "1319cc8604ca0cf46cd559632db880594766a1737768ff280e767777eada73bc"}, {"reversion": false, "end_ts": 1470698284, "start_ts": 1470611817, "name": "development", "docker_image_id": "1319cc8604ca0cf46cd559632db880594766a1737768ff280e767777eada73bc"}, {"reversion": false, "end_ts": 1470611817, "start_ts": 1470393518, "name": "development", "docker_image_id": "9fc7c175a11091de696ee91b2bffd15ca4b719aec836f2e291f22b157f7e6186"}, {"reversion": false, "end_ts": 1470393518, "start_ts": 1470352632, "name": "development", "docker_image_id": "3b67043b6c1d9a7d01f83561195f0592c712f1017735bfecbed2ea69b99cda09"}, {"reversion": false, "end_ts": 1470352632, "start_ts": 1470266192, "name": "development", "docker_image_id": "4a37b5a17058c1dca500599fcaa5ef70847a798950b89c6bfa375f4d00df9947"}, {"reversion": false, "start_ts": 1470236340, "name": "candidate", "docker_image_id": "fb38f27d3c97e1d23b07100b9cfefe4e91ee5c5373f192ba5033cf31fdbf40fb"}, {"reversion": false, "start_ts": 1470236306, "name": "2016-08-03-1457", "docker_image_id": "fb38f27d3c97e1d23b07100b9cfefe4e91ee5c5373f192ba5033cf31fdbf40fb"}, {"reversion": false, "end_ts": 1470266192, "start_ts": 1470179823, "name": "development", "docker_image_id": "fb38f27d3c97e1d23b07100b9cfefe4e91ee5c5373f192ba5033cf31fdbf40fb"}, {"reversion": false, "end_ts": 1470179823, "start_ts": 1470093363, "name": "development", "docker_image_id": "3e244c1f724758f98aa7fb7daa53f12974a46712ecc44e90551a212829b19574"}, {"reversion": false, "end_ts": 1470236340, "start_ts": 1470063743, "name": "candidate", "docker_image_id": "3dff55143ca5aa1052192180401d3f8524ffd2d3ce4d8af861bbd5c45c3b1d5f"}, {"reversion": false, "start_ts": 1470063699, "name": "2016-08-01-1501", "docker_image_id": "3dff55143ca5aa1052192180401d3f8524ffd2d3ce4d8af861bbd5c45c3b1d5f"}, {"reversion": false, "end_ts": 1470093363, "start_ts": 1470007168, "name": "development", "docker_image_id": "3dff55143ca5aa1052192180401d3f8524ffd2d3ce4d8af861bbd5c45c3b1d5f"}, {"reversion": false, "end_ts": 1470007168, "start_ts": 1469748012, "name": "development", "docker_image_id": "2151f5d6f451bf73e1cfef27cd228831238e4307de52ad6f253b506dcbf6fd61"}, {"reversion": false, "end_ts": 1470668730, "start_ts": 1468933123, "name": "soul3", "docker_image_id": "fa8b4fbd3d564be568052d1b236a7acdcf126f8e44efe333a7bfb27df197dd45"}, {"reversion": false, "start_ts": 1468933071, "name": "2016-07-19-1255", "docker_image_id": "fa8b4fbd3d564be568052d1b236a7acdcf126f8e44efe333a7bfb27df197dd45"}, {"reversion": false, "end_ts": 1470063743, "start_ts": 1468918589, "name": "candidate", "docker_image_id": "fa8b4fbd3d564be568052d1b236a7acdcf126f8e44efe333a7bfb27df197dd45"}, {"reversion": false, "start_ts": 1468918548, "name": "2016-07-19-0855", "docker_image_id": "fa8b4fbd3d564be568052d1b236a7acdcf126f8e44efe333a7bfb27df197dd45"}, {"reversion": false, "start_ts": 1468496655, "name": "2016-07-14-1143", "docker_image_id": "d7af892cc1275225ba2e489c970b7c98d951a14f5b3aabee618a7ea1efdf0d6d"}, {"reversion": false, "start_ts": 1468338407, "name": "2016-07-12-1546", "docker_image_id": "69687ef52c1590fee113dd6619826e71246b0164efcba01c3ead95eba7a66135"}, {"reversion": false, "start_ts": 1468251462, "name": "2016-07-11-1537", "docker_image_id": "f372a0d02723e5b3f2a8f9ab00b2bbf57e347139d9c5be09f89205fce8976ec7"}, {"reversion": false, "start_ts": 1467034932, "name": "2016-06-27-1342", "docker_image_id": "1a16492f952029abedb48f3e0de36c8bafacbfdfc9fe5a60750c1d00df25d24d"}, {"reversion": false, "start_ts": 1466677002, "name": "2016-06-23-1016", "docker_image_id": "1a16492f952029abedb48f3e0de36c8bafacbfdfc9fe5a60750c1d00df25d24d"}, {"reversion": false, "start_ts": 1466435981, "name": "2016-06-20-1519", "docker_image_id": "8cf81f2607b541e6500cf8207e3282e04b0f8b2ac1a529e4e83e75cba6f9a493"}, {"reversion": false, "start_ts": 1465917491, "name": "2016-06-14-1518", "docker_image_id": "296985879d4d1c1cdf37d87e653842c55d2ccecfea395fb88ac4a60c89a65816"}, {"reversion": false, "start_ts": 1465915117, "name": "hh", "docker_image_id": "296985879d4d1c1cdf37d87e653842c55d2ccecfea395fb88ac4a60c89a65816"}, {"reversion": false, "start_ts": 1465915080, "name": "2016-06-14-1437", "docker_image_id": "296985879d4d1c1cdf37d87e653842c55d2ccecfea395fb88ac4a60c89a65816"}, {"reversion": false, "start_ts": 1465225294, "name": "2016-06-06-1501", "docker_image_id": "296985879d4d1c1cdf37d87e653842c55d2ccecfea395fb88ac4a60c89a65816"}, {"reversion": false, "start_ts": 1464164039, "name": "2016-05-25-0813", "docker_image_id": "91dfd76583c435cdd5bcc771d2630e9e05f220ab3c172878a57aea457f64ecf6"}, {"reversion": false, "start_ts": 1463583963, "name": "2016-05-18-1506", "docker_image_id": "91dfd76583c435cdd5bcc771d2630e9e05f220ab3c172878a57aea457f64ecf6"}, {"reversion": false, "start_ts": 1463133644, "name": "2016-05-13", "docker_image_id": "91dfd76583c435cdd5bcc771d2630e9e05f220ab3c172878a57aea457f64ecf6"}, {"reversion": false, "start_ts": 1463068019, "name": "2016-05-12", "docker_image_id": "91dfd76583c435cdd5bcc771d2630e9e05f220ab3c172878a57aea457f64ecf6"}, {"reversion": false, "start_ts": 1462784234, "name": "2016-05-09", "docker_image_id": "91dfd76583c435cdd5bcc771d2630e9e05f220ab3c172878a57aea457f64ecf6"}, {"reversion": false, "start_ts": 1462549885, "name": "2016-05-06", "docker_image_id": "91dfd76583c435cdd5bcc771d2630e9e05f220ab3c172878a57aea457f64ecf6"}, {"reversion": false, "start_ts": 1462377565, "name": "2016-05-04", "docker_image_id": "91dfd76583c435cdd5bcc771d2630e9e05f220ab3c172878a57aea457f64ecf6"}, {"reversion": false, "start_ts": 1462275670, "name": "2016-05-03-a2", "docker_image_id": "91dfd76583c435cdd5bcc771d2630e9e05f220ab3c172878a57aea457f64ecf6"}, {"reversion": false, "start_ts": 1462261222, "name": "2016-05-03", "docker_image_id": "91dfd76583c435cdd5bcc771d2630e9e05f220ab3c172878a57aea457f64ecf6"}, {"reversion": false, "start_ts": 1462186105, "name": "2016-05-02", "docker_image_id": "91dfd76583c435cdd5bcc771d2630e9e05f220ab3c172878a57aea457f64ecf6"}, {"reversion": false, "start_ts": 1461931988, "name": "2016-04-29", "docker_image_id": "91dfd76583c435cdd5bcc771d2630e9e05f220ab3c172878a57aea457f64ecf6"}, {"reversion": false, "start_ts": 1461857308, "name": "2016-04-28-a2", "docker_image_id": "91dfd76583c435cdd5bcc771d2630e9e05f220ab3c172878a57aea457f64ecf6"}, {"reversion": false, "start_ts": 1461833266, "name": "2016-04-28", "docker_image_id": "91dfd76583c435cdd5bcc771d2630e9e05f220ab3c172878a57aea457f64ecf6"}, {"reversion": false, "start_ts": 1461673460, "name": "2016-04-26", "docker_image_id": "93e104cddb783bad420c26ec75199e00e99d987bdb3dc47c503170d34d9d9e5f"}, {"reversion": false, "start_ts": 1461670787, "name": "kd-cache-except", "docker_image_id": "3ee5f4ed5108026902b32d2716ed7073e29b1dd0dde2aa124b357e23e5228c25"}]}`)
				break
			case "2":
				w.WriteHeader(200)
				w.Header().Set("Content-Type", "application/json")
				fmt.Fprintln(w, `{"has_additional": false, "page": 2, "tags": [{"reversion": false, "start_ts": 1461596844, "name": "2016-04-25", "docker_image_id": "a266edda942ba6e284328090d3acb3da67d6aeca77f221860d91f73570755e0f"}, {"reversion": false, "start_ts": 1461587810, "name": "kd-cache2", "docker_image_id": "7e232f4cb858dff3b222b9a01928acb06edca1842be8c0de38749326c6b27dae"}, {"reversion": false, "start_ts": 1461587719, "name": "kd-cache", "docker_image_id": "faa3433b3c3220dc17fc9d558d6803e09757b209f5fa4efd1fd4f7e4418f871a"}, {"reversion": false, "start_ts": 1461166987, "name": "sop3", "docker_image_id": "32aa7d2f5cea7d15b011f8c08fac59b0fcbf81e19c8b912196cde43f033c14c0"}, {"reversion": false, "start_ts": 1461166822, "name": "releasetest", "docker_image_id": "32aa7d2f5cea7d15b011f8c08fac59b0fcbf81e19c8b912196cde43f033c14c0"}]}`)
				break
			default:
				w.WriteHeader(404)
				break
			}
		} else {
			w.WriteHeader(405)
		}

	}))

	mux.Handle("/api/v1/repository/experimentalplatform/skvs/tag/foobar", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == "PUT" {
			var payload struct {
				Image string `json:"image"`
			}

			decoder := json.NewDecoder(r.Body)
			err := decoder.Decode(&payload)
			if err != nil {
				w.WriteHeader(400)
			}

			if len(payload.Image) == 64 && len(strings.Trim(payload.Image, "0123456789ABCDEFabcdef")) == 0 {
				w.WriteHeader(201)
			} else {
				w.WriteHeader(400)
			}
		} else {
			w.WriteHeader(405)
		}

	}))

	return mux
}

func TestMain(m *testing.M) {
	server := httptest.NewServer(getMux())
	u, _ := url.Parse(server.URL)

	http.DefaultClient.Transport = RewriteTransport{URL: u}

	os.Exit(m.Run())
}

func TestGetTagImage(t *testing.T) {
	id, err := getTagImage("skvs", "experimentalplatform", "development", "foobar token")
	if err != nil {
		t.Fatal(err)
	}

	expectedID := "8b8cd46eeab0b530d0fcb64de26fe62fd68e736fc627c526933b680d3ae5291f"

	if id != expectedID {
		t.Fatalf("Expected ID is '%s', got '%s'", expectedID, id)
	}
}

func TestGetTagImage2(t *testing.T) {
	tag := "no-such-tag"
	id, err := getTagImage("skvs", "experimentalplatform", tag, "foobar token")
	if err == nil {
		t.Fatalf("Tag '%s' should not exist, but found ID '%s'", tag, id)
	}

	if _, ok := err.(*errorQuayTagNotFound); !ok {
		typename := reflect.TypeOf(err).Name()
		t.Fatalf("Should have received an errorQuayTagNotFound, got a %s instead", typename)
	}
}

func TestSetTagImage(t *testing.T) {
	tag := "foobar"
	err := setTagImage("skvs", "experimentalplatform", tag, "8b8cd46eeab0b530d0fcb64de26fe62fd68e736fc627c526933b680d3ae5291f", "foobar token")
	if err != nil {
		t.Fatal(err)
	}
}
