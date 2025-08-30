package com.jne_solutions.jne_household_app.glance

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.action.ActionParameters
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.*
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.actionStartActivity
import android.net.Uri

import android.appwidget.AppWidgetManager
import androidx.glance.appwidget.GlanceAppWidgetManager

import com.jne_solutions.jne_household_app.MainActivity
import com.jne_solutions.jne_household_app.R
import com.jne_solutions.jne_household_app.parseJsonList

data class Category(
  val id: Int,
  val name: String,
  val total: String,
  val fraction: String,
  val colorR: Int,
  val colorG: Int,
  val colorB: Int,
  val colorA: Int,
  val textColorR: Int,
  val textColorG: Int,
  val textColorB: Int,
  val textColorA: Int
)

class CategoriesWidget : GlanceAppWidget() {

  /** Needed for Updating */
  override val stateDefinition = HomeWidgetGlanceStateDefinition()

  override suspend fun provideGlance(context: Context, id: GlanceId) {
    provideContent {
      val appWidgetManager = AppWidgetManager.getInstance(context)
      val glanceAppWidgetManager = GlanceAppWidgetManager(context)
      val appWidgetId = glanceAppWidgetManager.getAppWidgetId(id)
      val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
      val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)

      val maxItems = calculateMaxItems(minHeight)

      GlanceContent(
          context = context,
          currentState = currentState(),
          maxItems = maxItems
      )
    }
  }

  private fun calculateMaxItems(widgetHeightDp: Int, itemHeightDp: Int = 56, spacingDp: Int = 4): Int {
    return ((widgetHeightDp + spacingDp).toFloat() / (itemHeightDp + spacingDp)).toInt().coerceAtLeast(1)
  }

  @Composable
  private fun GlanceContent(context: Context, currentState: HomeWidgetGlanceState, maxItems: Int) {
    val data = currentState.preferences

    val currency = data.getString("currency", "")!!
    val language = data.getString("language", "")!!
    val totalConnector = data.getString("totalConnector", "")!!
    val totalFrom = data.getString("totalFrom", "")!!
    val json = data.getString("categoryList", "[]")!!
    val categories: List<Category>  = parseJsonList(json) {
      Category(
          id = it["id"] as Int,
          name = it["name"] as String,
          total = it["total"] as String,
          fraction = it["fraction"] as String,
          colorR = it["colorR"] as Int,
          colorG = it["colorG"] as Int,
          colorB = it["colorB"] as Int,
          colorA = it["colorA"] as Int,
          textColorR = it["textColorR"] as Int,
          textColorG = it["textColorG"] as Int,
          textColorB = it["textColorB"] as Int,
          textColorA = it["textColorA"] as Int
      )
    }

    val langCode = language.take(2)

    val visibleCategories = categories.take(maxItems)

    Column(
      modifier = GlanceModifier
          .background(ColorProvider(R.color.widget_bg))
    ) {
      visibleCategories.forEachIndexed { index, category ->
        val formattedAmount = if (langCode in listOf("de", "fr", "es", "it", "pt")) {
          "${category.total} $currency"
        } else {
          "$currency ${category.total}"
        }
        val formattedFractionAmount = if (langCode in listOf("de", "fr", "es", "it", "pt")) {
          "${category.fraction} $currency"
        } else {
          "$currency ${category.fraction}"
        }

        val textColor = Color(
          alpha = category.textColorA,
          red = category.textColorR,
          green = category.textColorG,
          blue = category.textColorB
        )

        val backgroundColor = Color(
          alpha = category.colorA,
          red = category.colorR,
          green = category.colorG,
          blue = category.colorB
        )

        Row(
          modifier = GlanceModifier
            .fillMaxWidth()
            .padding(vertical = 6.dp)
            .background(ColorProvider(backgroundColor),)
            .padding(8.dp),
          verticalAlignment = Alignment.CenterVertically,
          horizontalAlignment = Alignment.Start
        ) {
          Column(
            modifier = GlanceModifier.defaultWeight()
          ) {
            Text(
              text = category.name,
              style = TextStyle(
                color = ColorProvider(textColor),
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold
              )
            )
            Text(
              text = "$formattedFractionAmount $totalFrom $formattedAmount $totalConnector",
              style = TextStyle(
                color = ColorProvider(textColor),
                fontSize = 12.sp
              )
            )
          }

          Text(
            text = "+",
            style = TextStyle(
              color = ColorProvider(textColor),
              fontSize = 28.sp,
              fontWeight = FontWeight.Bold
            ),
            modifier = GlanceModifier
            .padding(start = 8.dp)
            .padding(end = 8.dp)
            .clickable(
              onClick = actionStartActivity<MainActivity>(
                context,
                Uri.parse("PureBudget://addExpense?categoryId=${category.id}")
              )
            )
          )
        }
        if (index < visibleCategories.lastIndex) {
          Box(modifier = GlanceModifier.height(4.dp)) {}
        }
        
      }
    }
  }
}