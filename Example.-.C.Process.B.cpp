/// Example: Process A
#include <iostream>    // using IO functions
#include <string>      // using string
#include <windows.h>
#include <vector>
//#include <psapi.h>

#include <sstream> //for std::stringstream
#include "_SharedVar.cpp"


/// NOTE: For definitions read more in SharedVar.h

using namespace std;

int main(){

    int iTmp;int iTargetProcessPid; int pTargetProcessPointer = 0; string sTmp1;



    /// Load SharedVar functions
    Class_SharedVar SharedVar;

    /// Initialize (Must call it once before using the functions)
    SharedVar.initialize();

    cout << "Write the *target_process information:" << endl;
    cout << "   Enter the PID of Process A: "; cin >> iTargetProcessPid;
    cout << "   Enter the pointer for *info of Process A: "; cin >> sTmp1;
    pTargetProcessPointer = SharedVar.StrPtr2IntPtr(&sTmp1);




    /// Add new target process and set it to be the active one
    iTmp = SharedVar.SetNewTargetProcess(iTargetProcessPid,pTargetProcessPointer);
    //iTmp = SharedVar.SetNewTargetProcess(8676,0x00A38968);
    /// NOTE 1: If you are going to use .CreateLinker & .Update then you must first set
    ///         the target process by .SetNewTargetProcess or .SetTargetProcess
    /// NOTE 2: If error then the return is (int)<0. If not error then the return is 1
    if (iTmp < 0) {cout << "Problem in setting and adding the process."; return -1;}


    /// Declare the *copy_variable(s)
    /// NOTE 1: The data type must be exactly the same!
    int iValue1 = 0;
    char sValue2[255] = "";
    /// In this case - because the variable intended to be copy to its parallel variable,
    /// you should assign to it empty value. It will get the value later from the *parallel_variable


    /// Create *linker(s) for these^ variables to their *parallel_variable(s) that stored
    /// in the *target_process (Defined by SetNewTargetProcess or SetTargetProcess).
    C_oVarLinker iValue1_linker = SharedVar.CreateLinker(1,&iValue1,sizeof(iValue1));
    C_oVarLinker sValue2_linker = SharedVar.CreateLinker(2,&sValue2,sizeof(sValue2));
    /// NOTE 1: You must set the *target_process and ensure that there is no error in
    ///          this operation. make sure that SetNewTargetProcess or SetTargetProcess
    ///          did not return error before using .CreateLinker().
    /// NOTE 2: If error then *linker.pTargetPtr is equal to -1
    if (iValue1_linker.pTargetPtr == -1) {cout << "Problem in creating linker to iValue1."; return -2;}


    /// Update the *copy_variable(s) to the values of their *parallel_variable(s) using the *linker(s)
    SharedVar.UpdateIn(&iValue1_linker); /* Read the value of iValue1 (*parallel_variable) using iValue1_linker (*linker)
    --> Save the returned value in iValue1 (*copy_variable) using iValue1_linker (*linker)                                                 */
    SharedVar.UpdateIn(&sValue2_linker); /* Read the value of sValue2 (*parallel_variable) using sValue2_linker (*linker)
    --> Save the returned value in sValue2 (*copy_variable) using sValue2_linker (*linker)                                                 */

    /// Print the *copy_variable(s)
    cout << endl <<
    "Declared shared variables:" << endl <<
    "iValue1 = " << iValue1 << endl <<
    "sValue2 = " << sValue2 << endl << endl;


    int iUserChoise = 0; char cInput;
    cout <<
    "What do you want to do now?" << endl <<
    "1 = Print iValue1 , 2 = Print sValue2 , 3 = change iValue1 , 4 = change sValue2 5 = Exit" << endl;

    while (1) {
        cin >> iUserChoise;
        switch (iUserChoise){
        case 1:
            SharedVar.UpdateIn(&iValue1_linker); /// Update the value of iValue1 (*copy_variable) to the new value
                                                 /// of iValue1 (*parallel_variable) using iValue1_linker (*linker)

            cout << "^ --> The value of iValue1 is " << iValue1 << endl; /// Print the value of iValue1 (*copy_variable)
            break;
        case 2:
            SharedVar.UpdateIn(&sValue2_linker); /// Update the value of sValue2 (*copy_variable) to the new value
                                                 /// of sValue2 (*parallel_variable) using sValue2_linker (*linker)

            cout << "^ --> The value of sValue2 is " << sValue2 << endl; /// Print the value of sValue2 (*copy_variable)
            break;
        case 3:
            cout << "^ --> Write the new value for iValue1 (must be int):" << endl;
            cin >> iValue1;                       /// Change the value of iValue1 (*copy_variable)

            SharedVar.UpdateOut(&iValue1_linker); /// Update the value of iValue1 (*parallel_variable) to the new value
                                                  /// of iValue1 (*copy_variable) using iValue1_linker (*linker)

            cout << "^ --> The value changed to: " << iValue1 << endl; /// Print the value of iValue1 (*copy_variable)
            break;
        case 4:
            cout << "^ --> Write the new value for sValue2:" << endl;
            cin >> sValue2;                       /// Change the value of sValue2 (*copy_variable)

            SharedVar.UpdateOut(&sValue2_linker); /// Update the value of sValue2 (*parallel_variable) to the new value
                                                  /// of sValue2 (*copy_variable) using sValue2_linker (*linker)
            cout << "^ --> The value changed to: " << sValue2 << endl; /// Print the value of sValue2 (*copy_variable)
            break;

        case 5:
            return 1;

        default:
            cout << "Only 1,2,3,4,5 are valid." << endl;

        }


    }


}
