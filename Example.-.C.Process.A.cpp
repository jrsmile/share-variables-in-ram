/// Example: Process A
#include <iostream>    // using IO functions
#include <string>      // using string
#include <windows.h>
#include <vector>
//#include <psapi.h>

#include <sstream> //for std::stringstream
#include "_SharedVar.h"

/// NOTE: For definitions read more in SharedVar.h

using namespace std;

int main(){
    cout <<
    "Preparing for declaration..."
    << endl;

    /// Load SharedVar functions
    Class_SharedVar SharedVar;

    /// Initialize (Must call it once before using the functions)
    SharedVar.initialize();


    cout << endl <<
    "This process (This is the *target_process from the viewpoint of Process B):" << endl <<
    "   PID: " << GetCurrentProcessId() << endl <<
    /// Only type 1 supported in c++
    "   Pointer for *info (Pointer type 1): " + SharedVar.spSharedVars
    << endl << endl;


    cout <<
    "Step 1: Declaring variables ... (allocating memory and declaring the varibles)"
    << endl;
    /// In Autoit you make the shared_variable with _SharedVar_DeclareVar.
    /// In C++ (STEP 1) you declare the variable normally (** EXACTLY the same data type )

/// data type                value                                                        data type   value
       int   iValue1    =      10       ; /// Equivalent to "_SharedVar_DeclareVar($iValue1, 'int'   ,  10 )"
      char sValue1[255] = "Hello world!"; /// Equivalent to "_SharedVar_DeclareVar($sValue1,'char[255]','Hello world!')"

    /// Then (STEP 2) you share the variable with .share
    cout <<
    "Step 2: Sharing variables ..."
    << endl << endl ;
    ///           (id)                                                    (id)
    SharedVar.share(1,&iValue1); /// Equivalent to "_SharedVar_DeclareVar($iValue1,'int',10)"
    SharedVar.share(2,&sValue1); /// Equivalent to "_SharedVar_DeclareVar($sValue1,'char[255]','Hello world!')"

    /// ^ This is also called *parallel_variable from the view point of process b.


    cout <<
    "Declared shared variables:" << endl <<
    "iValue1 = " << iValue1 << endl <<
    "sValue1 = " << sValue1 << endl << endl;

    cout <<
    "Info: when the process from outside will try to connect to these variables," << endl <<
    "it will get this string: " << SharedVar.cSharedVars << endl <<
    "using the pointer " << SharedVar.spSharedVars << " (Pointer type 1)" << endl << endl;
    //(Pointer type 1)


    int iUserChoise = 0; char cInput;
    cout <<
    "What do you want to do now?" << endl <<
    "1 = Print iValue1 , 2 = Print sValue1 , 3 = change iValue1 , 4 = change sValue1 5 = Exit" << endl;

    while (1) {
        cin >> iUserChoise;
        switch (iUserChoise){
        case 1:
            cout << "^ --> The value of iValue1 is " << iValue1 << endl;
            break;
        case 2:
            cout << "^ --> The value of sValue1 is " << sValue1 << endl;
            break;
        case 3:
            cout << "^ --> Write the new value for iValue1 (must be int):" << endl;
            cin >> iValue1;
            cout << "^ --> The value changed to: " << iValue1 << endl;
            break;
        case 4:
            cout << "^ --> Write the new value for sValue1:" << endl;
            cin >> sValue1; /// Equivalent to "L_iVar2 = <Your new value>"
            cout << "^ --> The value changed to: " << sValue1 << endl;
            break;

        case 5:
            return 1;

        default:
            cout << "Only 1,2,3,4,5 are valid." << endl;
        }
    }




}
