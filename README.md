# vmFromSpecializedVHD
Powershell Script to create a VM from a specialised VHD

VHD must be in same storage account that the VM is to be created in.

Copy from one storage account to another with AzCopy:

```
AzCopy https://sourceaccount.blob.core.windows.net/mycontainer1 https://destaccount.blob.core.windows.net/mycontainer2 /sourcekey:key1 /destkey:key2 abc.txt
```
