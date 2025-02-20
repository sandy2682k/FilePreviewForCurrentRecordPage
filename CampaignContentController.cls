/**
* @File Name : CampaignContentController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : February 20, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | February 20, 2025 |   | Initial Version
**/

public with sharing class CampaignContentController {
    @AuraEnabled
    public static FileWrapper getFileDetails(String recordId) {
        System.debug('Entering getFileDetails method with recordId: ' + recordId);
        try {
            // Query the latest content document link for the record
            List<ContentDocumentLink> contentLinks = [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :recordId 
                ORDER BY SystemModstamp DESC 
                LIMIT 1
            ];

            if (contentLinks.isEmpty()) {
                System.debug('No file found for this record.');
                throw new AuraHandledException('No file found for this record.');
            }

            System.debug('ContentDocumentId retrieved: ' + contentLinks[0].ContentDocumentId);

            // Get the latest version of the content document
            ContentVersion contentVersion = [
                SELECT Id, Title, FileType, ContentSize, ContentDocumentId, 
                       VersionNumber, FileExtension, ContentLocation, ContentUrl
                FROM ContentVersion 
                WHERE ContentDocumentId = :contentLinks[0].ContentDocumentId
                AND IsLatest = true 
                LIMIT 1
            ];

            System.debug('ContentVersion retrieved: ' + contentVersion);
            return new FileWrapper(contentVersion);
        } catch (Exception e) {
            System.debug('Exception in getFileDetails: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class FileWrapper {
    // Class properties
    @AuraEnabled public String contentVersionId { get; set; }
    @AuraEnabled public String title { get; set; }
    @AuraEnabled public String fileType { get; set; }
    @AuraEnabled public Long contentSize { get; set; }
    @AuraEnabled public String contentType { get; set; }
    @AuraEnabled public String fileExtension { get; set; }

    // Constructor
    public FileWrapper(ContentVersion cv) {
        System.debug('Initializing FileWrapper with ContentVersion: ' + cv);
        this.contentVersionId = cv.Id;
        this.title = cv.Title;
        this.fileType = cv.FileType;
        this.contentSize = cv.ContentSize;
        this.fileExtension = cv.FileExtension;
        
        // Determine content type based on file extension
        this.contentType = getContentTypeFromExtension(cv.FileExtension);
    }

    // Method to get content type from file extension
    private String getContentTypeFromExtension(String extension) {
        if (String.isBlank(extension)) return 'application/octet-stream';
        
        Map<String, String> extensionToContentType = new Map<String, String>{
            'pdf' => 'application/pdf',
            'png' => 'image/png',
            'jpg' => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'gif' => 'image/gif',
            'bmp' => 'image/bmp',
            'doc' => 'application/msword',
            'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'xls' => 'application/vnd.ms-excel',
            'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'ppt' => 'application/vnd.ms-powerpoint',
            'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
            'csv' => 'text/csv',
            'txt' => 'text/plain'
        };
        
        String contentType = extensionToContentType.get(extension.toLowerCase());
        return contentType != null ? contentType : 'application/octet-stream';
    }
}
}
