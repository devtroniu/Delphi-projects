# git


NotionPARAInterfaces

 implements a connection to Notion.so, gets data from 4 datasets
 via REST calls and stores them in TObjectDictionary objects in memory,
 resolving the relations between them.

 A main index is maintained, also in an TObjectDictionary, to ease the
 search in memory.

 This is a refactored and improved version of NotionPARA that uses interfaces
 to add generalization to the different data types and to resolve issues of
 circular reference.

 A class factory resolves the creation of different types of data (pages and
 datasets).

 The calls to Notion are threaded, improving the response times.


logged run:


29 18:38:15:263 - ===== REST Client NotionPARAInterfaces created
29 18:38:15:263 -  !!! failed to create dataset dstGeneric
29 18:38:15:263 - starting initialization thread for dstAreasResources
29 18:38:15:263 - starting initialization thread for dstProjects
29 18:38:15:263 - starting initialization thread for dstTasks
29 18:38:15:263 - starting initialization thread for dstNotes
29 18:38:15:263 -  !!! failed to create dataset dstSomethingNew
29 18:38:15:263 - ===== REST Client NotionPARAInterfaces_b9067327e06f4b69a22f4c938d34622f created
29 18:38:15:263 - retrive dataset info - threaded
29 18:38:15:263 - TNotionRESTClient.DOGet: databases/b9067327e06f4b69a22f4c938d34622f
29 18:38:15:263 - ===== REST Client NotionPARAInterfaces_b1f45fec158848c5bda33a635ffd7628 created
29 18:38:15:263 - retrive dataset info - threaded
29 18:38:15:263 - ===== REST Client NotionPARAInterfaces_e9c75646f7164979a364f98d39371720 created
29 18:38:15:263 - retrive dataset info - threaded
29 18:38:15:263 - ===== REST Client NotionPARAInterfaces_b267f1af322f44d5b7081b8b5a29dd4a created
29 18:38:15:263 - retrive dataset info - threaded
29 18:38:15:263 - TNotionRESTClient.DOGet: databases/b267f1af322f44d5b7081b8b5a29dd4a
29 18:38:15:263 - TNotionRESTClient.DOGet: databases/b1f45fec158848c5bda33a635ffd7628
29 18:38:15:263 - TNotionRESTClient.DOGet: databases/e9c75646f7164979a364f98d39371720
29 18:38:15:653 - Request Executed. Status: OK
29 18:38:15:653 - Projects [PT] found.
29 18:38:15:653 - ===== NotionPARAInterfaces_b9067327e06f4b69a22f4c938d34622f BYE =====
29 18:38:15:669 - Request Executed. Status: OK
29 18:38:15:669 - Request Executed. Status: OK
29 18:38:15:669 - Tasks [PT] found.
29 18:38:15:669 - ===== NotionPARAInterfaces_b1f45fec158848c5bda33a635ffd7628 BYE =====
29 18:38:15:669 - Notes [PT] found.
29 18:38:15:669 - ===== NotionPARAInterfaces_e9c75646f7164979a364f98d39371720 BYE =====
29 18:38:15:701 - Request Executed. Status: OK
29 18:38:15:701 - Areas/Resources [PT] found.
29 18:38:15:701 - ===== NotionPARAInterfaces_b267f1af322f44d5b7081b8b5a29dd4a BYE =====
29 18:38:15:701 - All initialization threads have completed.
29 18:38:15:701 - starting thread for Areas/Resources [PT]
29 18:38:15:701 - starting thread for Notes [PT]
29 18:38:15:701 - starting thread for Projects [PT]
29 18:38:15:701 - starting thread for Tasks [PT]
29 18:38:15:701 - ===== REST Client NotionPARAInterfaces_e9c75646f7164979a364f98d39371720 created
29 18:38:15:701 - fetching for Notes [PT], call body: {"page_size": 100}
29 18:38:15:701 - ===== REST Client NotionPARAInterfaces_b9067327e06f4b69a22f4c938d34622f created
29 18:38:15:701 - ===== REST Client NotionPARAInterfaces_b1f45fec158848c5bda33a635ffd7628 created
29 18:38:15:701 - TNotionRESTClient.DOPost databases/b9067327e06f4b69a22f4c938d34622f/query
29 18:38:15:701 - TNotionRESTClient.DOPost databases/b1f45fec158848c5bda33a635ffd7628/query
29 18:38:15:701 - TNotionRESTClient.DOPost databases/e9c75646f7164979a364f98d39371720/query
29 18:38:15:701 - ===== REST Client NotionPARAInterfaces_b267f1af322f44d5b7081b8b5a29dd4a created
29 18:38:15:701 - TNotionRESTClient.DOPost databases/b267f1af322f44d5b7081b8b5a29dd4a/query
29 18:38:16:077 - Request Executed. Status: OK
29 18:38:16:077 - fetching for Tasks [PT] ended with 23 pages.
29 18:38:16:077 - ===== NotionPARAInterfaces_b1f45fec158848c5bda33a635ffd7628 BYE =====
29 18:38:16:530 - Request Executed. Status: OK
29 18:38:16:530 - fetching for Projects [PT] ended with 14 pages.
29 18:38:16:530 - ===== NotionPARAInterfaces_b9067327e06f4b69a22f4c938d34622f BYE =====
29 18:38:17:234 - Request Executed. Status: OK
29 18:38:17:249 - fetching for Notes [PT], call body: {"page_size": 100, "start_cursor": "eafbc61f-2960-4c01-99ca-b404f574440d"}
29 18:38:17:249 - TNotionRESTClient.DOPost databases/e9c75646f7164979a364f98d39371720/query
29 18:38:17:297 - Request Executed. Status: OK
29 18:38:17:297 - fetching for Areas/Resources [PT] ended with 32 pages.
29 18:38:17:297 - ===== NotionPARAInterfaces_b267f1af322f44d5b7081b8b5a29dd4a BYE =====
29 18:38:18:750 - Request Executed. Status: OK
29 18:38:18:766 - fetching for Notes [PT], call body: {"page_size": 100, "start_cursor": "9c665c43-8fa2-43d6-a11a-434bbefb8968"}
29 18:38:18:766 - TNotionRESTClient.DOPost databases/e9c75646f7164979a364f98d39371720/query
29 18:38:20:625 - Request Executed. Status: OK
29 18:38:20:644 - fetching for Notes [PT], call body: {"page_size": 100, "start_cursor": "b43da162-1b61-4a1b-aad9-ad272a9b67c8"}
29 18:38:20:644 - TNotionRESTClient.DOPost databases/e9c75646f7164979a364f98d39371720/query
29 18:38:31:910 - Request Executed. Status: OK
29 18:38:31:925 - fetching for Notes [PT], call body: {"page_size": 100, "start_cursor": "520c8d27-a6ba-408e-9da7-a0218b7ee0c1"}
29 18:38:31:925 - TNotionRESTClient.DOPost databases/e9c75646f7164979a364f98d39371720/query
29 18:38:33:980 - Request Executed. Status: OK
29 18:38:34:012 - fetching for Notes [PT], call body: {"page_size": 100, "start_cursor": "cf729807-66ac-44fa-9210-5f60e5115f62"}
29 18:38:34:012 - TNotionRESTClient.DOPost databases/e9c75646f7164979a364f98d39371720/query
29 18:38:35:236 - Request Executed. Status: OK
29 18:38:35:251 - fetching for Notes [PT], call body: {"page_size": 100, "start_cursor": "37b94b5a-0ac7-4d28-a773-b2f054a6b444"}
29 18:38:35:251 - TNotionRESTClient.DOPost databases/e9c75646f7164979a364f98d39371720/query
29 18:38:37:444 - Request Executed. Status: OK
29 18:38:37:459 - fetching for Notes [PT], call body: {"page_size": 100, "start_cursor": "6002bfa2-6e1a-4ac0-9581-40d07f320e63"}
29 18:38:37:459 - TNotionRESTClient.DOPost databases/e9c75646f7164979a364f98d39371720/query
29 18:38:38:992 - Request Executed. Status: OK
29 18:38:39:008 - fetching for Notes [PT], call body: {"page_size": 100, "start_cursor": "21a34242-431b-45a1-96a2-955338eea2ca"}
29 18:38:39:008 - TNotionRESTClient.DOPost databases/e9c75646f7164979a364f98d39371720/query
29 18:38:41:353 - Request Executed. Status: OK
29 18:38:41:369 - fetching for Notes [PT], call body: {"page_size": 100, "start_cursor": "88a01235-b0b1-4217-bf21-6aa3526bedb0"}
29 18:38:41:369 - TNotionRESTClient.DOPost databases/e9c75646f7164979a364f98d39371720/query
29 18:38:43:873 - Request Executed. Status: OK
29 18:38:43:887 - fetching for Notes [PT], call body: {"page_size": 100, "start_cursor": "16b19c5a-c29f-4c94-b927-3d4364070a24"}
29 18:38:43:887 - TNotionRESTClient.DOPost databases/e9c75646f7164979a364f98d39371720/query
29 18:38:45:426 - Request Executed. Status: OK
29 18:38:45:441 - fetching for Notes [PT], call body: {"page_size": 100, "start_cursor": "4f074a48-0a20-4c80-b3e9-4ab68a1de741"}
29 18:38:45:441 - TNotionRESTClient.DOPost databases/e9c75646f7164979a364f98d39371720/query
29 18:38:46:801 - Request Executed. Status: OK
29 18:38:46:833 - fetching for Notes [PT], call body: {"page_size": 100, "start_cursor": "a5ac9a5b-98cc-4841-ac35-131bb497a8be"}
29 18:38:46:833 - TNotionRESTClient.DOPost databases/e9c75646f7164979a364f98d39371720/query
29 18:38:48:690 - Request Executed. Status: OK
29 18:38:48:705 - fetching for Notes [PT] ended with 1276 pages.
29 18:38:48:705 - ===== NotionPARAInterfaces_e9c75646f7164979a364f98d39371720 BYE =====
29 18:38:48:705 - All threads have completed.
29 18:38:48:705 - Connecting pages done
