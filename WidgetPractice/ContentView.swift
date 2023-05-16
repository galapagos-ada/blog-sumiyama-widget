//
//  ContentView.swift
//  WidgetPractice
//
//  Created by taisei.sumiyama on 2023/05/02.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @State var name = ""
    @State var name1 = ""

    var body: some View {
        VStack {
            TextField("Github User Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button(action: {
                UserDefaults(suiteName: "group.com.WidgetPractice")?.set(name, forKey: "GithubUserName")
                /// Widgetの更新。
                WidgetCenter.shared.reloadTimelines(ofKind: "WidgetGlpgs")
            }, label: {
                Text("Update Widget")
                    .padding(10)
            })
            Text(name1)
            Button("hoge", action: {
                name1 = UserDefaults.standard.string(forKey: "GithubUserName") ?? "hoge"
            })
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
