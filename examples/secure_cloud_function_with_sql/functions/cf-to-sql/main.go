// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package cloudsql

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"database/sql"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"os"

	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/cloudevents/sdk-go/v2/event"
	"github.com/go-sql-driver/mysql"
	_ "github.com/go-sql-driver/mysql"
)

func init() {
	functions.CloudEvent("HelloCloudFunction", connect)
}

func connect(ctx context.Context, e event.Event) error {
	instanceProjectID := os.Getenv("INSTANCE_PROJECT_ID")
	instanceUser := os.Getenv("INSTANCE_USER")
	instancePWD := os.Getenv("INSTANCE_PWD")
	instanceLocation := os.Getenv("INSTANCE_LOCATION")
	instanceIP := os.Getenv("INSTANCE_IP")
	instancePort := os.Getenv("INSTANCE_PORT")
	instanceName := os.Getenv("INSTANCE_NAME")
	databaseName := os.Getenv("DATABASE_NAME")

	instanceConnectionName := fmt.Sprintf("%s:%s", instanceIP, instancePort)
	// instanceConnectionName := fmt.Sprintf("%s:%s:%s", instanceProjectID, instanceLocation, instanceName)
	dbURI := fmt.Sprintf("%s:%s@tcp(%s)/%s?parseTime=true",
		instanceUser, instancePWD, instanceConnectionName, databaseName)

	if dbRootCert, ok := os.LookupEnv("DB_ROOT_CERT"); ok { // e.g., '/path/to/my/server-ca.pem'
		pool := x509.NewCertPool()
		pem, err := ioutil.ReadFile(dbRootCert)
		if err != nil {
			return err
		}
		if ok := pool.AppendCertsFromPEM(pem); !ok {
			return errors.New("unable to append root cert to pool")
		}
		mysql.RegisterTLSConfig("cloudsql", &tls.Config{
			RootCAs:               pool,
			InsecureSkipVerify:    true,
			VerifyPeerCertificate: verifyPeerCertFunc(pool),
		})
		dbURI += "&tls=cloudsql"
	}
	// [START cloud_sql_mysql_databasesql_connect_tcp]

	// db is the pool of database connections.
	log.Printf("Connecting to %s:%s:%s using IP %s and port %s", instanceProjectID, instanceLocation, instanceName, instanceIP, instancePort)
	db, err := sql.Open("mysql", dbURI)
	if err != nil {
		return fmt.Errorf("sql.Open: %w", err)
	}

	err = db.Ping()
	if err != nil {
		log.Fatal(err)
		fmt.Errorf("Error during ping.", err)
	}

	var (
		id          int
		name        string
		performance string
	)

	fmt.Println("Select from table.")
	res, err := db.Query("SELECT * FROM characters")

	for res.Next() {
		err := res.Scan(&id, &name, &performance)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(fmt.Sprintf("%v: %s: %s", id, name, performance))
	}

	return err
}

// verifyPeerCertFunc returns a function that verifies the peer certificate is
// in the cert pool.
func verifyPeerCertFunc(pool *x509.CertPool) func([][]byte, [][]*x509.Certificate) error {
	return func(rawCerts [][]byte, _ [][]*x509.Certificate) error {
		if len(rawCerts) == 0 {
			return errors.New("no certificates available to verify")
		}

		cert, err := x509.ParseCertificate(rawCerts[0])
		if err != nil {
			return err
		}

		opts := x509.VerifyOptions{Roots: pool}
		if _, err = cert.Verify(opts); err != nil {
			return err
		}
		return nil
	}
}
