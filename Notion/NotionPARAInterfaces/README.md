# git


NotionPARAInterfaces

 Is based on the classes from NotionInterfaces.

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


 Ideas to improve:
   - done. implement an observer mechanism between manager and datasets
   - implement Tags
   - add a list of properties at the level of Page
   - implement connection between entities
   - add a graphical interface
     - ?
     - ??
