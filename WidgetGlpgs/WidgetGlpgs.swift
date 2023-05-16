//
//  WidgetGlpgs.swift
//  WidgetGlpgs
//
//  Created by taisei.sumiyama on 2023/05/08.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    /// 最初に仮で表示されるWidget。
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent(), githubUserInfoModel: nil)
    }
    /// ウィジェットギャラリー表示用。
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration, githubUserInfoModel: GithubUserInfoModel.fake())
        completion(entry)
    }

    /// ここでWidgetのライフサイクル制御。
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            var entries: [SimpleEntry] = []
            let currentDate = Date()
            let githubUserInfoModel: GithubUserInfoModel?

            let entryDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
            do {
                githubUserInfoModel = try await ApiClient.fetch()
            } catch {
                githubUserInfoModel = nil
            }
            let entry = SimpleEntry(date: entryDate, configuration: configuration, githubUserInfoModel: githubUserInfoModel)
            entries.append(entry)
            
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    var date: Date
    let configuration: ConfigurationIntent
    let githubUserInfoModel: GithubUserInfoModel?
}

enum ApiClient {
    static func fetch() async throws -> GithubUserInfoModel {
        let userName = try getUserDefault()
        let githubUserInfoUrl = "https://api.github.com/users/\(userName)"

        guard let url = URL(string: githubUserInfoUrl) else {
            throw GlpgsError.URLError
        }
        do {
            let (data, urlResponse) = try await URLSession.shared.data(from: url)
            guard let httpStatus = urlResponse as? HTTPURLResponse else {
                throw GlpgsError.responseDataError
            }
            switch httpStatus.statusCode {
            case 200:
                let jsonDecoder = JSONDecoder()
                jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                guard let response = try? jsonDecoder.decode(GithubUserInfoModel.self, from: data) else {
                    throw GlpgsError.decodeError
                }
                return response
            default:
                throw GlpgsError.httpStatusError(httpStatus.statusCode)
            }
        } catch {
            throw GlpgsError.serverError
        }
    }
    static func getImage() -> UIImage {
        do {
            let userName = try getUserDefault()
            let imageUrl = "https://github.com/\(userName).png"
            
            if let imageURl = URL(string: imageUrl),
               let imageData = try? Data(contentsOf: imageURl),
               let image = UIImage(data: imageData) {
                return image
            }
        } catch {
            return UIImage(systemName: "nosign")!
        }
        return .init()
    }
    
    private static func getUserDefault() throws -> String {
        guard let userName = UserDefaults(suiteName: "group.com.WidgetPractice")?.string(forKey: "GithubUserName") else {
            throw GlpgsError.UserDefaultError
        }
        print("hhugahuga")
        return userName
    }
}

enum GlpgsError: Error {
    case URLError
    case responseDataError
    case httpStatusError(Int)
    case serverError
    case decodeError
    case UserDefaultError
}

struct GithubUserInfoModel: Codable {
    let name: String
    let location: String?
    let publicRepos: Int

    public static func fake() -> GithubUserInfoModel {
        GithubUserInfoModel(name: "Glpgs", location: "Japan", publicRepos: 1)
    }
}

struct WidgetGlpgsEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        /// サイズ毎にViewのカスタマイズ
        if entry.githubUserInfoModel == nil {
            Text("init")
        } else {
            switch widgetFamily {
            case .systemMedium:
                HStack() {
                    Image(uiImage: ApiClient.getImage())
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                    VStack(alignment: .leading) {
                        Text(entry.githubUserInfoModel!.location ?? "Japan")
                        Text(entry.githubUserInfoModel!.name)
                        Text("PubRepos:  \(entry.githubUserInfoModel!.publicRepos)")
                    }
                }
            default:
                Image(uiImage: ApiClient.getImage())
                    .resizable()
            }
        }
    }
}

struct WidgetGlpgs: Widget {
    let kind: String = "WidgetGlpgs"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            WidgetGlpgsEntryView(entry: entry)
        }
        /// WidgetNameは日本語禁止。入れるとWidget一覧に表示されない。
        .configurationDisplayName("Widget Name")
        /// WidgetNameの説明。
        .description("Widgetの名前")
        /// WidgetNameのサイズ一覧。
        .supportedFamilies([
            /// accessoryXXXはロック画面用。iOS16〜
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular,
            /// サイズ一覧
            /// ExtraLargeはiPadOS用みたい。（https://developer.apple.com/documentation/widgetkit/widgetfamily/systemextralarge）
            .systemExtraLarge,
            .systemLarge,
            .systemMedium,
            .systemSmall
        ])
    }
}

/// 良さそう　https://qiita.com/uhooi/items/8319a19c9d01c7e54935
struct WidgetGlpgs_Previews: PreviewProvider {
    static var previews: some View {
        WidgetGlpgsEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), githubUserInfoModel: GithubUserInfoModel.fake()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
