package data

import (
	"fmt"
	"go-stock/backend/logger"
	"strings"
	"testing"

	"github.com/duke-git/lancet/v2/random"
)

// @Author spark
// @Date 2025/6/19 13:05
// @Desc
//-----------------------------------------------------------------------------------

func TestAnalyzeSentiment(t *testing.T) {

	news := NewMarketNewsApi().GetNewsList2("", random.RandInt(500, 1000))
	messageText := strings.Builder{}
	for _, telegraph := range *news {
		messageText.WriteString(telegraph.Content + "\n")
	}

	text := messageText.String()
	// 分析情感
	words := splitWords(text)
	fmt.Println(strings.Join(words, " "))
	result := AnalyzeSentiment(text)
	result, frequencies := AnalyzeSentimentWithFreqWeight(text)
	// 过滤标点符号和分隔符
	cleanFrequencies := FilterPunctuationAndSeparators(frequencies)
	// 输出结果
	logger.SugaredLogger.Infof("情感分析结果: %s (得分: %.2f, 正面词:%d, 负面词:%d)\n 词频统计结果: %v",
		result.Description,
		result.Score,
		result.PositiveCount,
		result.NegativeCount,
		cleanFrequencies,
	)

}
