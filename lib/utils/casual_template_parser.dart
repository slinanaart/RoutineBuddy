import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/casual_template_settings.dart';
import '../models/casual_template_action.dart';

class CasualTemplateParser {
  static Future<(CasualTemplateSettings, List<CasualTemplateAction>)> parseFromAsset(String assetPath) async {
    try {
      final String csvContent = await rootBundle.loadString(assetPath);
      final List<String> lines = csvContent.split('\n');
      
      // Parse settings section
      final Map<String, String> settings = {};
      int currentLine = 0;
      
      while (currentLine < lines.length && !lines[currentLine].trim().startsWith('Day,')) {
        final line = lines[currentLine].trim();
        if (line.isNotEmpty) {
          final parts = line.split(',');
          if (parts.length >= 2) {
            settings[parts[0]] = parts[1];
          }
        }
        currentLine++;
      }

      // Find the actions table header
      while (currentLine < lines.length && !lines[currentLine].trim().startsWith('Day,')) {
        currentLine++;
      }

      // Skip both header rows (there are two header rows in the CSV)
      currentLine++; // Skip first header row
      if (currentLine < lines.length && lines[currentLine].trim().startsWith('Day,')) {
        currentLine++; // Skip second header row if it exists
      }

      // Parse actions
      final List<CasualTemplateAction> actions = [];
      
      while (currentLine < lines.length) {
        final line = lines[currentLine].trim();
        if (line.isEmpty) {
          currentLine++;
          continue;
        }

        // Proper CSV parsing that handles quoted fields with commas
        final List<String> parts = _parseCSVLine(line);
        
        if (parts.length >= 4) {
          try {
            final Map<String, String> actionMap = {
              'Day': parts[0].trim(),
              'Time': parts[1].trim(),
              'Action': parts[2].trim(),
              'Category': parts[3].trim(),
              'Recommended Times': parts.length > 4 ? parts[4].trim() : '',
              'Frequency': parts.length > 5 && parts[5].trim().isNotEmpty ? parts[5].trim() : '1',
              'Premium': parts.length > 6 ? parts[6].trim() : 'no',
            };
            
            final action = CasualTemplateAction.fromMap(actionMap);
            actions.add(action);
          } catch (e) {
            print('Error parsing action at line $currentLine: $e');
          }
        }
        currentLine++;
      }

      return (
        CasualTemplateSettings.fromMap(settings),
        List<CasualTemplateAction>.from(actions),
      );
    } catch (e) {
      print('Error parsing CSV: $e');
      return (
        CasualTemplateSettings(
          wakeTime: const TimeOfDay(hour: 6, minute: 0),
          sleepTime: const TimeOfDay(hour: 22, minute: 30),
        ),
        <CasualTemplateAction>[],
      );
    }
  }
  
  // Helper method to properly parse CSV lines with quoted fields
  static List<String> _parseCSVLine(String line) {
    final List<String> fields = [];
    final StringBuffer currentField = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(currentField.toString());
        currentField.clear();
      } else {
        currentField.write(char);
      }
    }
    
    // Add the last field
    fields.add(currentField.toString());
    
    return fields;
  }
}
