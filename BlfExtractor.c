
#include "mex.h"
#include <tchar.h>                     /* RTL   */
#include <stdio.h>

#define STRICT                         /* WIN32 */
#include <windows.h>

#include "binlog.h"                    /* BL    */

int read_test( LPCTSTR pFileName, LPDWORD pRead)
{
    HANDLE hFile;
    VBLObjectHeaderBase base;
    VBLCANMessage message;
    VBLEnvironmentVariable variable;
    VBLEthernetFrame ethframe;
    VBLAppText appText;
    VBLFileStatisticsEx statistics = { sizeof( statistics)};
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

    BLGetFileStatisticsEx( hFile, &statistics);

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
              BLFreeObject( hFile, &message.mHeader.mBase);
            }
            break;
        case BL_OBJ_TYPE_ENV_INTEGER:
        case BL_OBJ_TYPE_ENV_DOUBLE:
        case BL_OBJ_TYPE_ENV_STRING:
        case BL_OBJ_TYPE_ENV_DATA:
            /* read environment variable */
            variable.mHeader.mBase = base;
            bSuccess = BLReadObjectSecure( hFile, &variable.mHeader.mBase, sizeof(variable));
            /* free memory for the environment variable */
            if( bSuccess) {
              BLFreeObject( hFile, &variable.mHeader.mBase);
            }
            break;
        case BL_OBJ_TYPE_ETHERNET_FRAME:
            /* read ethernet frame */
            ethframe.mHeader.mBase = base;
            bSuccess = BLReadObjectSecure( hFile, &ethframe.mHeader.mBase, sizeof(ethframe));
            /* free memory for the frame */
            if( bSuccess) {
              BLFreeObject( hFile, &ethframe.mHeader.mBase);
            }
            break;
        case BL_OBJ_TYPE_APP_TEXT:
            /* read text */
            appText.mHeader.mBase = base;
            bSuccess = BLReadObjectSecure( hFile, &appText.mHeader.mBase, sizeof(appText));
            if ( NULL != appText.mText)
            {
                printf( "%s\n", appText.mText);
            }
            /* free memory for the text */
            if( bSuccess) {
              BLFreeObject( hFile, &appText.mHeader.mBase);
            }
            break;
        default:
            /* skip all other objects */
            bSuccess = BLSkipObject( hFile, &base);
            break;
        }

        if ( bSuccess)
        {
          *pRead += 1;
        }
    }

    /* close file */
    if ( !BLCloseHandle( hFile))
    {
        return -1;
    }

    return bSuccess ? 0 : -1;
}

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
    LPCTSTR pFileName = _T( "test.blf");
    DWORD dwRead;
    int result = 0;
    
    result = read_test( pFileName, &dwRead);
  
}

