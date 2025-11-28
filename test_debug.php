<?php
// Simple test for debugging ZIP issue
error_log("=== DEBUG TEST START ===");

// Include VtigerCRM
chdir(dirname(__FILE__));
include_once 'vtlib/Vtiger/Module.php';

try {
    // Test record IDs
    $recordIds = ['126026', '126025'];
    error_log("Testing with record IDs: " . implode(',', $recordIds));
    
    // Check if records exist
    foreach($recordIds as $recordId) {
        $recordModel = Vtiger_Record_Model::getInstanceById($recordId, 'Invoice');
        if($recordModel) {
            error_log("Record $recordId exists: " . $recordModel->getDisplayName());
        } else {
            error_log("Record $recordId does NOT exist");
        }
    }
    
} catch(Exception $e) {
    error_log("ERROR in debug test: " . $e->getMessage());
}

error_log("=== DEBUG TEST END ===");
echo "Debug test completed. Check Apache error log.";
?>