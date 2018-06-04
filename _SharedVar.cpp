

#include <iostream>    // using IO functions
#include <string>      // using string
#include <windows.h>
#include <vector>
#include <sstream> //for std::stringstream


/*
#cs
								SharedVar C++ Version v1.0  (6.3.2016)
								Compatible with _SharedVar Autoit v2.3

								By gil900/GilEli

								Donation link:
								https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MZ9W63LBV86AN
#ce



*/

/*
################################################ Definitions ###############################################

    *Info
    Information that stored as a string value, that contains a list of all *shared_variable(s) that their value stored in the memory
    of the process that sharing them. The info look like this (this is the format):

        [ vvv Var 1 vvv] [vvvv Var 2  vvvv]   [vvvvv Var 3 vvvvv]
       "1,  0x02E903D0   ;  2  , 0x02EA9018 ;   3  , 0x02E90110"
       id    pointer      id2     pointer      id3     pointer
            to memory   of the	 to memory		      to memory
             address.   value	  address.			   address.

    When a process need to declare a *shared_variable then,
        a) If the value of the variable is stored in another process (*target_process), this process needs to know where the value
            is stored in the memory of the another process. and it get it from this^ list.
        b) If the value of the variable is stored inside, then this process needs to update it's own list
            so when another process need to make a connection, the another process will know the memory address
            of the target variable from this list.

        Every process that have at least one *shared_variable that its value stored inside -
        manage and maintain such a list.

    *target_process
		The process from outside that share variables
		(This process is also *target_process from the viewpoint of the *target_process)

		The *target_process is represented by:
		a) The process pid
		b) the pointer to the process *Info
		c) The type of the pointer (hidden gui or memory address)

		When you declare variable that it's source value stored in the memory of the *target_process (process from outside),
		then you need first to set the target process


    *copy_variable
    This process --> memory address of the copy variable (c++ type variable) (*linker.pInputPtr / &variable )


    *parallel_variable
    The *target_process --> memory address of the parallel variable (c++ type variable) (*linker.pTargetPtr)




    *linker
    is the Object class C_oVarLinker

        [.int pTargetPtr; ]
        [.int iSize;      ]
        [.void* pInputPtr;]
        [.HANDLE hPro;    ]

    ^ A linker between *copy_variable to *parallel_variable. The result is *shared_variable
    (but you make this result in your area (the high-level area) using the *linker).

    *copy_variable/*parallel_variable <--|*linker|---> *parallel_variable/*copy_variable
                                             v
                                      *shared_variable
    *shared_variable is composed of this ^. in c++ it looks very different.

    In Autoit *shared_variable is the *linker + the c type variable.
    In c++ you have only *Linker that links between c type variables that you declared before.



    NOTE:
    the memory address of *copy_variable must be always constant during the life time of the process.
    In Autoit you don't need to worry about it. but in c++ you must make sure that *copy_variable never been reallocated
    read more: http://lmgtfy.com/?q=c%2B%2B+prevent+reallocation

*/


using namespace std;


/// *********** THIS CLASS (Class_aOpenProcess) IS NOT FOR THE USER/HIGH LEVEL AREA *************
/// alternative array for $gg_sv_aOpenedPids + sub-functions for managing
/// this array
class Class_aOpenProcess
{
public:
/// $gg_sv_aOpenedPids
    vector<int> aiPid; //std::vector <int> test(10);
    vector<HANDLE> ahPro; //HANDLE ahPro[max_size] = {0};
    vector<int> apPtr; //int apPtr[max_size] = {0};
    //vector<int> apPtr_type; //int apPtr_type[max_size] = {0};


/// Functions
    /*
    void PrintData(){ /// <- Debug function to print the Array
        cout << "size: " << aiPid.size() << endl;
        for(int a = 0; a < aiPid.size(); a++)
        {
            cout << aiPid[a] << " , " << ahPro[a] << " , " << (LPVOID)apPtr[a] // << " , " << apPtr_type[a]
            << endl;

        }
    }
    */

    /// Function to add new PID to the array (like gg_sv_aOpenedPids).
    /// On success: return the index of the process in the array.
    /// On fail: return -1
    int AddProcess(int iPid,int pPtr){

        /// Open memory handle for the target process
        HANDLE hProcess = OpenProcess(PROCESS_ALL_ACCESS, TRUE, iPid);
        if (!hProcess) {return -1;} /// If error in opening the memory handle for the process then return -1


        /// Add the the info to the array
        aiPid.push_back(iPid);
        ahPro.push_back(hProcess);
        apPtr.push_back(pPtr);


        return aiPid.size()-1; /// Return the index as 0 based
    } /// Return the 0 based index if success. -1 if failed.


    /// Function to remove and close process
    bool RemoveProcess(int iProcessIndex){
        CloseHandle((HANDLE)ahPro[iProcessIndex]);
        aiPid.erase(aiPid.begin()+iProcessIndex,aiPid.begin()+iProcessIndex+1);
        ahPro.erase(ahPro.begin()+iProcessIndex,ahPro.begin()+iProcessIndex+1);
        apPtr.erase(apPtr.begin()+iProcessIndex,apPtr.begin()+iProcessIndex+1);
    }


    /// Function to look for the index in the array for the process
    int GetProcessIndex(int iPid){
        for (int a = 0; a < aiPid.size(); a++)
        {
            if (aiPid[a] == iPid) {return a;}
        }
        return -1;
    } /// return -1 if not found, return >= 0 if found

    /// Get the *Info from the target process as std::string
    string GetPointersFromProcess(int iProcessIndex){
        #define cSize 4000
        char cPointers[cSize];
        if(!ReadProcessMemory(ahPro[iProcessIndex],(LPVOID)apPtr[iProcessIndex],&cPointers,cSize,NULL)) {return "-1";}
        stringstream sPointers;
        sPointers << cPointers;
        return sPointers.str();
    }
};


/// ******** *FOR THE USER/HIGH LEVEL AREA:
/// The data structure for the *linker
class C_oVarLinker{
public:
    int pTargetPtr;
    int iSize;
    void* pInputPtr;
    HANDLE hPro;
};



class Class_SharedVar{
private: /// ********** NOT FOR THE USER *********
    int iActiveIndex = -1; /// The index of the active process
    Class_aOpenProcess aoProcess; /// Declare the alternative array for $gg_sv_aOpenedPids



    /// Extract the pointer from the *Info string --> return it as int
    /// Failure: -1, Success: Return (int)>0 (Pointer)
    int ExtractPointer(int iID,string *psSharedVars){
        /// Look for the pos of the pointer in the *Info string
        stringstream sTmp1;
        sTmp1 << iID << ',';
        int iPos = 0;
        iPos = (*psSharedVars).find(sTmp1.str());
        if (iPos == string::npos) {return -1;} // {return (int*)-1;}
        int a = iPos+2;
        if (a >= (*psSharedVars).length()-1) {return -1;}
        sTmp1.clear();sTmp1.str("");
        /// Build a string containing the requested pointer (using the pos)
        for (a;a <= (*psSharedVars).length()-1; a++){
            if ((*psSharedVars).at(a) == ';') {break;}
            sTmp1 << (*psSharedVars).at(a);
        }
        /// Convert the [pointer as string] to [pointer as int]


        long long unsigned int i;
        sTmp1>>std::hex>>i;
        /// Return the pointer as int
        return i;

        /*
        int * i_ptr=reinterpret_cast<int *>(i);
        cout << i_ptr << endl;
        return i_ptr;
        */
    }

public: /// ***** FUNCTIONS AND VARIABLES FOR THE USER *******
    char cSharedVars[4000] = ""; /// The *info
/*  Variable that stores as string all declared variables that their value is stored inside
    the memory of this process. the another process that need to access these variables, need this string
    Because the string contains all the info needed for the connection to these variables.
    The info in the string contains: [var id][the memory address of where the value stored]
    Every time you share variable with .share, this string is updated with the info about the new
    shared declared variable.
*/

    string spSharedVars; /// The pointer (as string) (only type 1) to the *info
/*  only the process from outside need this.
    from inside the *Info is accessible directly in .cSharedVars
*/

    /// initialize for the functions.
    /// NOTE 1: ***** You must call it once before using any functions in this library!
    void initialize(){
        #define max_size 10
        //aoProcess.iSize = 66;
        aoProcess.aiPid.reserve(max_size);
        aoProcess.ahPro.reserve(max_size);
        aoProcess.apPtr.reserve(max_size);
        //aoProcess.apPtr_type.reserve(max_size);

        stringstream sTmp;
        sTmp << &cSharedVars;
        spSharedVars = sTmp.str();
    }


    /// Share the variable with the other process
    /// iId = the identifier for the variable
    /// pPtr = the pointer for the variable (stored in this process) to share
    /// Failure: false, Success: true
    bool share(int iId,void* pPtr){
        #define sSplitChar1 ','
        #define sSplitChar2 ';'

        stringstream sSharedVars; sSharedVars << cSharedVars;
        stringstream sAdd ;sAdd << iId; sAdd << sSplitChar1;

        if (sSharedVars.str().find(sAdd.str()) != string::npos) {return false;}
        if (sSharedVars.str() != "") {sSharedVars << sSplitChar2;}

        /// Add the variable to the list
        sSharedVars << sAdd.str();
        sSharedVars << pPtr;
        strcpy(cSharedVars,sSharedVars.str().c_str());
        return true;
    }


    /// *** You must set target process before using this!!!
    /// In order to access *parallel_variable, you need to create *linker for it.
    /// This function intended to create the *linker.
    ///
    /// iID = the identifier of the *parallel_variable
    /// *pVar = The pointer for the *copy_variable
    /// iVarSize = The max size of the variable data type (You get it with sizeof())
    ///
    /// Failure: Object.pTargetPtr = -1, Success: Return the *linker (Object.*)
    C_oVarLinker CreateLinker(int iID,void *pVar,int iVarSize){
        C_oVarLinker oLinker; /// Declare linker object
        #define Execute_ReturnError oLinker.pTargetPtr = -1;return oLinker
        string sPointers = aoProcess.GetPointersFromProcess(iActiveIndex); /// Get *Info from the *target_process
        if (sPointers == "-1") {Execute_ReturnError;} /// If error then return error by .pTargetPtr = -1
        /// Extract pTargetPtr from *Info and save it in .pTargetPtr
        oLinker.pTargetPtr = ExtractPointer(iID,&sPointers);
        if (oLinker.pTargetPtr == -1) {Execute_ReturnError;}
        oLinker.pInputPtr = pVar;  /// Save the pointer of the input variable in .pInputPtr
        oLinker.hPro = aoProcess.ahPro[iActiveIndex]; /// Save the process handle in .hPro
        oLinker.iSize = iVarSize; /// Save the size of the value in .size
        return oLinker; /// Return the linker object
    }


    /// Update the *copy_variable to the value of *parallel_variable (Equivalent to _sv_read(*))
    /// Failure: false, Success: true
    bool UpdateIn(C_oVarLinker* oLinker){
        /// Read the value in the *parallel_variable --> save the output in the *copy_variable
        if (!   ReadProcessMemory((*oLinker).hPro,(LPVOID)(*oLinker).pTargetPtr,(*oLinker).pInputPtr,
                                (*oLinker).iSize,NULL)    )
            { return false; } /// Error: cannot read the value from the *parallel_variable
    }


    /// Update the *parallel_variable to the value of *copy_variable (Equivalent to _sv_write(*))
    bool UpdateOut(C_oVarLinker* oLinker){
        /// Write the value of  in the *parallel_variable --> save the output in the *copy_variable
        if (!   WriteProcessMemory((*oLinker).hPro,(LPVOID)(*oLinker).pTargetPtr,(*oLinker).pInputPtr,
                                (*oLinker).iSize,NULL)   )
            { return false; } /// Error: cannot read the value from the *parallel_variable
    }


    /// Set and add the new *target_process of where to connect the variables...
    /// iPid = need to be the pid of the *target_process
    /// iPtr = need to be memory address pointer to the *info in the *target_process
    /// Failure: (int)<0 -, Success: 1
    int SetNewTargetProcess(int iPid,int iPtr){

        /// If the process not found then add it.
        if (aoProcess.GetProcessIndex(iPid) != -1) {return -1;} /// -1 = Error: The process is not new.

        /// Add the process to the array.
        int iIndex = aoProcess.AddProcess(iPid,iPtr);
        if (iIndex == -1) {return -2;} /// -2 = Error: Problem in adding the process
        iActiveIndex = iIndex;
        return 1; /// 1 = Success to perform the operation
    }

    /// Set *target_process that was added before (not new process)
    /// iPid = need to be the pid of the *target_process
    /// Failure: (int)<0 -, Success: 1
    int SetTargetProcess(int iPid){
        int iIndex = aoProcess.GetProcessIndex(iPid);
        if (iIndex == -1) {return -1;} /// -1 = Error: The process not found (this process is new).
        iActiveIndex = iIndex;
        return 1;
    }



    /// Convert [Pointer as string] to [Pointer as int]
    int StrPtr2IntPtr(string *sPointer){
        int iPtr = 0;
        stringstream ssTmp;
        ssTmp << *sPointer;
        ssTmp >> std::hex >> iPtr;
        return iPtr;
    }


    /*
    bool Debug_PrintVars(){
        //cout << iActiveIndex << endl;
        //cout << aoProcess.aiPid.capacity() << endl;
        aoProcess.PrintData();
        //aoProcess.PrintData();
        cout << iActiveIndex << endl;
    }
    */

    /*
    string tmp = "cat";
    char tab2[1024];
    strcpy(tab2, tmp.c_str());
    */

    /*
    int abcd = 12;
    stringstream ss;
    ss << &abcd;
    string name = ss.str();
    */

};




