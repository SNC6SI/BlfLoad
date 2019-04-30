
#include "mex.h"
#include <tchar.h>                     /* RTL   */
#include <stdio.h>

#define STRICT                         /* WIN32 */
#include <windows.h>

#include "binlog.h"                    /* BL    */

int read_statistics(LPCTSTR pFileName, VBLFileStatisticsEx* pstatistics)
{
    HANDLE hFile;
    BOOL bSuccess;
    hFile = BLCreateFile( pFileName, GENERIC_READ);

    if ( INVALID_HANDLE_VALUE == hFile)
    {
        return -1;
    }

    BLGetFileStatisticsEx( hFile, pstatistics);
    
    if ( !BLCloseHandle( hFile))
    {
        return -1;
    }

    return bSuccess ? 0 : -1;
}



int read_info( LPCTSTR pFileName, LPDWORD pRead, double* b)
{
    HANDLE hFile;
    VBLObjectHeaderBase base;
    VBLCANMessage message;
    VBLCANMessage2 message2;
    unsigned int i;

    BOOL bSuccess;

    if ( NULL == pRead)
    {
        return -1;
    }

    *pRead = 0;

    /* open file */
    hFile = BLCreateFile( pFileName, GENERIC_READ);

    if ( INVALID_HANDLE_VALUE == hFile)
    {
        return -1;
    }


    bSuccess = TRUE;
    
    /* read base object header from file */
    while ( bSuccess && BLPeekObject( hFile, &base))
    {
        switch ( base.mObjectType)
        {
        case BL_OBJ_TYPE_CAN_MESSAGE:
            /* read CAN message */
            message.mHeader.mBase = base;
            bSuccess = BLReadObjectSecure( hFile, &message.mHeader.mBase, sizeof(message));
            /* free memory for the CAN message */
            if( bSuccess) {
              for(i=0;i<8;i++) *(b + (*pRead)*8 + i) = message.mData[i];
              BLFreeObject( hFile, &message.mHeader.mBase);
              *pRead += 1;
            }
            break;
        case BL_OBJ_TYPE_CAN_MESSAGE2:
            /* read CAN message */
            message2.mHeader.mBase = base;
            bSuccess = BLReadObjectSecure( hFile, &message2.mHeader.mBase, sizeof(message2));
            /* free memory for the CAN message */
            if( bSuccess) {
              for(i=0;i<8;i++) *(b + (*pRead)*8 + i) = message2.mData[i];
              BLFreeObject( hFile, &message2.mHeader.mBase);
              *pRead += 1;
            }
            break;
        case BL_OBJ_TYPE_ENV_INTEGER:
        case BL_OBJ_TYPE_ENV_DOUBLE:
        case BL_OBJ_TYPE_ENV_STRING:
        case BL_OBJ_TYPE_ENV_DATA:
        case BL_OBJ_TYPE_ETHERNET_FRAME:
        case BL_OBJ_TYPE_APP_TEXT:
        default:
            /* skip all other objects */
            bSuccess = BLSkipObject( hFile, &base);
            break;
        }
        //mexPrintf("%s%u\n", "count: ", *pRead);
    }

    /* close file */
    if ( !BLCloseHandle( hFile))
    {
        return -1;
    }

    return bSuccess ? 0 : -1;
}

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
    LPCTSTR pFileName = _T( "chan124_new.blf");
    DWORD dwRead;
    double *ptr;
    
    int result = 0;
    
    VBLFileStatisticsEx statistics = { sizeof( statistics)};
    result = read_statistics( pFileName, &statistics);

    
    plhs[0] = mxCreateDoubleMatrix (8,statistics.mObjectCount , mxREAL);
    ptr = mxGetPr(plhs[0]);
    result = read_info( pFileName, &dwRead, ptr);
    mxSetN(plhs[0],dwRead);
  
}

