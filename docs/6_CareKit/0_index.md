# CareKit

The `CMHealth` SDK provides the ability to synchronize data between your
CareKit app's local device store and  the 
[CloudMine Connected Health Cloud](http://cloudmineinc.com/platform/developer-tools/).

## Overview

CloudMine's platform offers a robust [`Snippet`](https://cloudmine.io/docs/#/server_code#logic-engine) and [`ACL`](https://cloudmine.io/docs/#/rest_api#user-data-security) framework, which are dependencies of the CMHealth framework when using CareKit. The CareKit SDK will automatically store `OCKCarePlanActivity` and `OCKCarePlanEvent` objects in the logged-in user-level data store. In order to grant a CareProvider access to this data, the `ACL` framework and a server-side `Logic Engine Snippet` is required to properly attach the appropriate `acl_id`. 