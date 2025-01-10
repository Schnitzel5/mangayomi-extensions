const mangayomiSources = [{
    "name": "Weeb Central",
    "lang": "en",
    "baseUrl": "https://weebcentral.com",
    "apiUrl": "",
    "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/en.weebcentral.png",
    "typeSource": "single",
    "itemType": 0,
    "version": "0.0.1",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "manga/src/en/weebcentral.js"
}];

class DefaultExtension extends MProvider {
    getHeaders(url) {
        return {
            Referer: this.source.baseUrl
        };
    }
    mangaListFromPage(res) {
        const doc = new Document(res.body);
        const mangaElements = doc.select("article > section");
        const list = [];
        for (const element of mangaElements) {
            const name = element.selectFirst("a > article > div > div > div").text;
            const imageUrl = element.selectFirst("img").getSrc;
            const link = element.selectFirst("a").getHref;
            list.push({ name, imageUrl, link });
        }
        const hasNextPage = doc.selectFirst("button > span").text === "View More Results...";
        return { "list": list, hasNextPage };
    }
    toStatus(status) {
        if (status == "Ongoing")
            return 0;
        else if (status == "Completed")
            return 1;
        else if (status == "Hiatus")
            return 2;
        else if (status == "Canceled")
            return 3;
        else
            return 5;
    }
    parseDate(date) {
        return String(new Date(date).valueOf());
    }

    async getPopular(page) {
        const res = await new Client().get(`${this.source.baseUrl}/search/data?limit=32&offset=${(page - 1) * 32}&sort=Popularity&order=Descending&official=Any&display_mode=Full+Display`);
        return this.mangaListFromPage(res);
    }

    async getLatestUpdates(page) {
        const res = await new Client().get(`${this.source.baseUrl}/search/data?limit=32&offset=${(page - 1) * 32}&sort=Latest+Updates&order=Descending&official=Any&display_mode=Full+Display`);
        return this.mangaListFromPage(res);
    }
    async search(query, page, filters) {
        const res = await new Client().get(`${this.source.baseUrl}/search/data?limit=32&offset=${(page - 1) * 32}&text=${query}&sort=Popularity&order=Descending&official=Any&display_mode=Full+Display`);
        return this.mangaListFromPage(res);
    }

    async getDetail(url) {
        const res = await new Client().get(url);
        const doc = new Document(res.body);
        const imageUrl = doc.selectFirst("picture > img")?.getSrc;
        const description = doc.selectFirst("section > section > ul > li > p")?.text.trim();
        const author = doc
          .select("section > ul > li > span > a")
          .map((el) => el.text.trim())
          .join(", ");
        const status = this.toStatus(doc.selectFirst("h3:contains('Status')").nextElementSibling.text.trim());
        const genre = doc.selectFirst("h3:contains('Genres')").nextElementSibling.select("button.text-white")
            .map((e) => e.text.trim());

        const chapRes = await new Client().get(url.substring(0, url.lastIndexOf("/")) + "full-chapter-list", {
            "Referer": url
        });
        const chapDoc = new Document(chapRes.body);
        const chapters = [];
        const chapterElements = chapDoc.select("a");
        for (const element of chapterElements) {
            const url = element.getHref;
            const name = element.selectFirst("span.items-center > span").text;
            let dateUpload;
            try {
                const dateText = element.selectFirst("time")?.text.trim();
                const cleanDateText = dateText.replace(/(\d+)(st|nd|rd|th)/, "$1");
                dateUpload = this.parseDate(cleanDateText);
            } catch (_) {
                dateUpload = null
            }
            chapters.push({ name, url, dateUpload });
        }
        return {
            imageUrl,
            description,
            genre,
            author,
            author,
            status,
            chapters
        };
    }

    async getPageList(url) {
        const res = await new Client().get(this.source.baseUrl + "/series/" + url);
        const scriptData = new Document(res.body).select("script:contains(self.__next_f.push)").map((e) => e.text.substringAfter("\"").substringBeforeLast("\"")).join("");
        const match = scriptData.match(/\\"pages\\":(\[.*?])/);
        if (!match) {
            throw new Error("Failed to find chapter pages");
        }
        const pagesData = match[1];

        const pageList = JSON.parse(pagesData.replace(/\\(.)/g, "$1"))
            .sort((a, b) => a.order - b.order);
        return pageList;
    }

    getSourcePreferences() {
        return [];
    }

}