const functions = require("firebase-functions");
const fetch = require("node-fetch"); // Наш http-клиент
const cors = require("cors")({origin: true}); // Наш обработчик CORS

// Создаем HTTP-функцию с именем 'getNews'
exports.getNews = functions.https.onRequest((request, response) => {

  // 1. Оборачиваем все в 'cors', чтобы разрешить запросы из браузера
  cors(request, response, async () => {

    // 2. Это URL, который блокировался
    const targetUrl = "https://travelpress.kz/news/kazakhstan";

    try {
      // 3. Делаем запрос с сервера (здесь нет CORS)
      const fetchResponse = await fetch(targetUrl);

      if (!fetchResponse.ok) {
        // 4. Если сайт-источник вернул ошибку, пересылаем ее
        response.status(fetchResponse.status).send("Failed to fetch from external source");
        return;
      }

      // 5. Получаем ответ в виде ТЕКСТА (так как это HTML-страница, а не JSON)
      const responseBody = await fetchResponse.text();

      // 6. Устанавливаем правильный заголовок, чтобы браузер понял, что это HTML
      response.set("Content-Type", "text/html; charset=utf-8");

      // 7. Отправляем успешный ответ (HTML-код новостей) обратно в наше Flutter-приложение
      response.status(200).send(responseBody);

    } catch (error) {
      console.error("Proxy Error:", error);
      response.status(500).send(`Proxy error: ${error.message}`);
    }
  });
});