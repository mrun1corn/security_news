import 'package:security_news/data/models/news_source.dart';

class AppConstants {
  static const List<NewsSource> defaultSources = [
    // Cybersecurity
    NewsSource(
      name: 'The Hacker News',
      url: 'https://feeds.feedburner.com/TheHackersNews',
      iconUrl: 'https://thehackernews.com/favicon.ico',
      category: NewsCategory.cybersecurity,
    ),
    NewsSource(
      name: 'KrebsOnSecurity',
      url: 'https://krebsonsecurity.com/feed/',
      iconUrl: 'https://krebsonsecurity.com/favicon.ico',
      category: NewsCategory.cybersecurity,
    ),
    NewsSource(
      name: 'BleepingComputer',
      url: 'https://www.bleepingcomputer.com/feed/',
      iconUrl: 'https://www.bleepingcomputer.com/favicon.ico',
      category: NewsCategory.cybersecurity,
    ),
    // Antivirus
    NewsSource(
      name: 'Malwarebytes Labs',
      url: 'https://blog.malwarebytes.com/feed/',
      iconUrl: 'https://www.malwarebytes.com/favicon.ico',
      category: NewsCategory.antivirus,
    ),
    NewsSource(
      name: 'Naked Security',
      url: 'https://nakedsecurity.sophos.com/feed/',
      iconUrl: 'https://nakedsecurity.sophos.com/favicon.ico',
      category: NewsCategory.antivirus,
    ),
    // Technology
    NewsSource(
      name: 'The Register',
      url: 'https://www.theregister.com/headlines.atom',
      iconUrl: 'https://www.theregister.com/favicon.ico',
      category: NewsCategory.technology,
    ),
    // DevOps
    NewsSource(
      name: 'DevOps.com',
      url: 'https://devops.com/feed/',
      iconUrl: 'https://devops.com/favicon.ico',
      category: NewsCategory.devops,
    ),
    NewsSource(
      name: 'The New Stack',
      url: 'https://thenewstack.io/feed/',
      iconUrl: 'https://thenewstack.io/favicon.ico',
      category: NewsCategory.devops,
    ),
    // Infrastructure
    NewsSource(
      name: 'DataCenterKnowledge',
      url: 'https://www.datacenterknowledge.com/rss.xml',
      iconUrl: 'https://www.datacenterknowledge.com/favicon.ico',
      category: NewsCategory.infrastructure,
    ),
    // Virtualization
    NewsSource(
      name: 'vSphere-Land',
      url: 'https://vsphere-land.com/feed',
      iconUrl: 'https://vsphere-land.com/favicon.ico',
      category: NewsCategory.virtualization,
    ),
  ];
}
