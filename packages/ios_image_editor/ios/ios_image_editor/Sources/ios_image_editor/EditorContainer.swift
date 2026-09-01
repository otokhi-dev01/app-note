import SwiftUI

struct EditorContainer: View {
    @Environment(\.presentationMode) private var presentationMode

    @State var image: UIImage
    var originalPath: String
    var completion: (String?) -> Void

    var body: some View {
        NavigationView {
            MarkupEditor(
                image: $image,
                originalPath: originalPath
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .edgesIgnoringSafeArea(.all)
            .navigationBarTitle("Edit Image", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    completion(nil)
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    completion(originalPath)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
