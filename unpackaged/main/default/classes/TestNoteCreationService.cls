@isTest
private class TestNoteCreationService {
	@isTest
    public static void shouldAllowAddingANoteToALead() {
        Lead l = new Lead(LastName = 'Kuiper', Email = 'gwilym@gearset.com', Company = 'Unknown', LeadSource='Inbound');
        insert l;
        
        NoteCreationService n = new NoteCreationService();
        n.createNote(l.Id, 'Hello', 'World');
        
        List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :l.Id];
        System.assertEquals(1, contentDocumentLinks.size());
    }
}