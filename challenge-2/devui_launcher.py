# challenge-2/devui_launcher.py
#!/usr/bin/env python3
"""
Azure Trust Agents - Challenge 2 DevUI Launcher

This script launches the DevUI for the 4-agent fraud detection workflow with MCP integration.
"""

import argparse
import logging
import os
import sys
from pathlib import Path

# Add the agents directory to the path
current_dir = Path(__file__).parent
agents_dir = current_dir / "agents"
sys.path.insert(0, str(agents_dir))

from dotenv import load_dotenv

# Load environment variables
load_dotenv(override=True)

def setup_logging():
    """Setup logging configuration"""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )

def check_environment():
    """Check if required environment variables are set"""
    required_vars = [
        "AI_FOUNDRY_PROJECT_ENDPOINT",
        "MODEL_DEPLOYMENT_NAME",
        "COSMOS_ENDPOINT",
        "COSMOS_KEY",
        "MCP_SERVER_ENDPOINT",
        "APIM_SUBSCRIPTION_KEY",
        "FRAUD_ALERT_AGENT_ID"
    ]
    
    missing_vars = []
    for var in required_vars:
        if not os.environ.get(var):
            missing_vars.append(var)
    
    if missing_vars:
        print("❌ Missing required environment variables:")
        for var in missing_vars:
            print(f"   - {var}")
        print("\nPlease set these variables in your .env file.")
        return False
    
    print("✅ All required environment variables are set")
    return True

def launch_workflow_devui(port: int = 8083):
    """Launch DevUI with the Challenge 2 workflow"""
    from agent_framework.devui import serve
    
    # Import workflow
    try:
        # Change to agents directory to properly import
        os.chdir(agents_dir)
        
        from sequential_workflow_chal2 import (
            customer_data_executor,
            risk_analyzer_executor, 
            compliance_report_executor,
            fraud_alert_executor
        )
        from agent_framework import WorkflowBuilder
        
        # Build the 4-agent workflow
        workflow = (
            WorkflowBuilder(
                name="Challenge 2: Fraud Detection Workflow with MCP",
                description="4-executor workflow: Customer Data → Risk Analyzer → (Compliance Report + Fraud Alert in parallel)"
            )
            .set_start_executor(customer_data_executor)
            .add_edge(customer_data_executor, risk_analyzer_executor)
            .add_edge(risk_analyzer_executor, compliance_report_executor)
            .add_edge(risk_analyzer_executor, fraud_alert_executor)
            .build()
        )
        
        print(f"🚀 Launching Challenge 2 DevUI on port {port}")
        print(f"🔄 Workflow: 4-Agent Fraud Detection with MCP Integration")
        print(f"   Architecture: Customer Data → Risk Analyzer → [Compliance Report + Fraud Alert]")
        print(f"🌐 Access at: http://localhost:{port}")
        print("\n💡 Features:")
        print("   • Real-time Cosmos DB integration")
        print("   • Azure AI Foundry agents")
        print("   • MCP Server integration for fraud alerts")
        print("   • Parallel executor processing")
        print("   • Complete audit trail generation")
        
        serve(entities=[workflow], port=port, auto_open=True)
        
    except ImportError as e:
        print(f"❌ Error importing workflow: {e}")
        print("\nMake sure you're in the correct directory and all dependencies are installed.")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error launching DevUI: {e}")
        sys.exit(1)

def main():
    """Main function to launch DevUI"""
    parser = argparse.ArgumentParser(
        description="Azure Trust Agents Challenge 2 DevUI Launcher",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                    # Launch workflow on default port 8083
  %(prog)s --port 8090        # Launch on custom port

Environment Variables Required:
  AI_FOUNDRY_PROJECT_ENDPOINT - Azure AI Foundry project endpoint
  MODEL_DEPLOYMENT_NAME       - Model deployment name
  COSMOS_ENDPOINT            - Cosmos DB endpoint
  COSMOS_KEY                 - Cosmos DB key
  MCP_SERVER_ENDPOINT        - MCP server URL
  APIM_SUBSCRIPTION_KEY      - API Management subscription key
  FRAUD_ALERT_AGENT_ID       - Fraud Alert Agent ID
        """
    )
    
    parser.add_argument(
        "--port",
        type=int,
        default=8083,
        help="Port to run the server on (default: 8083)"
    )
    
    parser.add_argument(
        "--no-env-check",
        action="store_true",
        help="Skip environment variable validation"
    )
    
    args = parser.parse_args()
    
    # Setup logging
    setup_logging()
    
    print("=" * 70)
    print("🏦 Azure Trust Agents - Challenge 2: MCP Integration DevUI")
    print("=" * 70)
    
    # Check environment variables unless skipped
    if not args.no_env_check and not check_environment():
        sys.exit(1)
    
    try:
        launch_workflow_devui(args.port)
            
    except KeyboardInterrupt:
        print("\n👋 DevUI stopped by user")
    except Exception as e:
        print(f"❌ Error launching DevUI: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()