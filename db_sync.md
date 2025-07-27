# DB Sync diagram and description

Pure Budget features a unique way to sync changes between multiple instances. To make it more obvious to other people it will be pictured and explained here.
Synchronization is realised using an external encrypted file. The file serves as a tranfer database similar to a secondary node.
This means there are multiple primary nodes using a common secondary to communicate asynchronously.
Therefore no extra database server is needed to process changes.
All instances primarily use their own internal database. Every change generates an editLog entry.
In the second step the editLog entry is used to append the changes to the secondary node.

## Requirements

- primary and secondary node have all tables to be synced in common
- local editLog entries to be synced have the id "-1"

## Full Process

```mermaid
graph LR;
  A(["Perform local change (insert, update, delete)"]);
  B(["Write editLog entry *"]);
  C(["Download encrypted db file for secondary"]);
  D(["Decrypt using key from keystore"]);
  E(["Push Phase"]);
  F(["Pull Phase"]);
  G{Changes made};
  H(["Skip upload"]);
  I(["Encrypt secondary file"]);
  J(["Upload secondary file"]);
  K(["End"]);
  L{File reachable?}


  A-->B;
  B-->L;
  L-->C;
  C-->D;
  D-->E;
  E-->F;
  F-->G;
  G-->H;
  G-->I;
  I-->J;
  H-->K;
  J-->K;
  L-->K;
```

\* Params: ```affectedTable <String>, affectedId <int>, type <String>, sharedBatchID <int>```

## Push-Phase

```mermaid
graph LR;
  A(["Read all editLog enties with id = -1"]);
  B(["Append change count to counter"]);
  C(["Read database entry for each change and insert into secondary"]);
  D{ID changed?};
  E(["Write entry into changedIdHelper"]);
  F(["Write editLog entry with new sharedBatchID into secondary"]);
  G(["Update local entries with new IDs*"]);
  H{Changes present?};
  I(["End"]);

  A-->B;
  B-->H;
  H-->C;
  C-->D;
  D-->E;
  E-->F;
  D-->F;
  F-->G;
  G-->I;
  H-->I;
```

\* IMPORTANT: reversed order to avoid ID conflicts and update editLog in case the script fails in next step

## Pull-Phase

```mermaid
graph LR;
  A(["Read lastProcessedBatchID (effectively timestamp in millis)"]);
  B(["Read all editLog enties from secondary after lastProcessedBatchID"]);
  C(["Reduce changes to reduce sync time*"]);
  D(["Append change count to counter"]);
  E(["Read database entry for each change and insert into primary"]);
  F(["Cleanup local editLog to save space"]);
  G{Changes present?};
  H(["Update lastProcessedBatchID in local cache on primary to current timestamp"]);
  I(["Update lastProcessedBatchID in local cache on primary to highest timestamp from changes"]);
  J(["End"]);

  A-->B;
  B-->C;
  C-->D;
  D-->G;
  G-->E;
  E-->F;
  F-->I;
  G-->H;
  H-->J;
  I-->J;
```

\* if affectedTable and affectedId change a reduce is performed by type:

- insert + delete => no action
- update + delete => no action
- insert + update + delete => no action
- insert + update => insert (due to sync logic)
- update => update
- insert => insert
- delete => delete
  - as IDs are not assigned twice even if an entry was deleted a simple detection is enough

### Notes

- Updating sharedBatchIDs on local is not necessary as the log is emptied at the end
- It is only necessary if the editLog is to be kept
